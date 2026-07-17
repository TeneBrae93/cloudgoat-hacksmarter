import os
import re
import glob
import shutil
import subprocess

AWS_DIR = "/home/tyler/dev/cloud-labs/cloudgoat/cloudgoat/scenarios/aws"

def get_hcl_blocks(content, block_type):
    results = []
    pattern = re.compile(rf'^{block_type}\s+"([^"]+)"\s*(?:"([^"]+)")?\s*{{', re.MULTILINE)
    
    for match in pattern.finditer(content):
        start_idx = match.start()
        name1 = match.group(1)
        name2 = match.group(2)
        
        brace_count = 0
        in_string = False
        escape = False
        end_idx = -1
        
        search_start = content.find('{', start_idx)
        for i in range(search_start, len(content)):
            c = content[i]
            if escape:
                escape = False
                continue
            if c == '\\':
                escape = True
                continue
            if c == '"' and not in_string:
                in_string = True
            elif c == '"' and in_string:
                in_string = False
                
            if not in_string:
                if c == '{':
                    brace_count += 1
                elif c == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        end_idx = i + 1
                        break
        
        if end_idx != -1:
            results.append({
                'name1': name1,
                'name2': name2,
                'start_idx': start_idx,
                'end_idx': end_idx,
                'content': content[start_idx:end_idx]
            })
    return results

def find_starting_access_key(tf_dir):
    out_files = glob.glob(os.path.join(tf_dir, "output*.tf"))
    key_counts = {}
    for out_file in out_files:
        with open(out_file, 'r') as f:
            content = f.read()
            matches = re.findall(r'aws_iam_access_key\.([^.]+)\.', content)
            for m in matches:
                key_counts[m] = key_counts.get(m, 0) + 1
    
    if len(key_counts) == 1:
        return list(key_counts.keys())[0]
    elif key_counts:
        for k in key_counts:
            if 'start' in k.lower() or 'initial' in k.lower() or 'admin' in k.lower():
                return k
        return list(key_counts.keys())[0]
    return None

def process_scenario(scenario_path):
    print(f"Processing {scenario_path}...")
    tf_dir = os.path.join(scenario_path, "terraform")
    if not os.path.exists(tf_dir):
        print("  No terraform directory.")
        return False
        
    # Copy assets into terraform/ if it exists in the scenario root
    src_assets = os.path.join(scenario_path, "assets")
    dest_assets = os.path.join(tf_dir, "assets")
    if os.path.exists(src_assets):
        if os.path.exists(dest_assets):
            shutil.rmtree(dest_assets)
        shutil.copytree(src_assets, dest_assets)
        print("  Copied assets folder.")
        
    # Generate SSH keys if referenced
    need_keys = False
    need_whitelist = False
    
    # Read all files to check for external references and modify them
    tf_files = glob.glob(os.path.join(tf_dir, "*.tf"))
    for tf_file in tf_files:
        with open(tf_file, 'r') as f:
            content = f.read()
            
        if "cloudgoat.pub" in content or "cloudgoat" in content:
            need_keys = True
        if "whitelist.txt" in content:
            need_whitelist = True
            
        # Update external paths to point locally
        modified = False
        new_content = content
        
        # Replace ../assets/ with assets/
        if "../assets/" in new_content:
            new_content = new_content.replace("../assets/", "assets/")
            modified = True
            
        # Replace ../cloudgoat.pub with cloudgoat.pub
        if "../cloudgoat.pub" in new_content:
            new_content = new_content.replace("../cloudgoat.pub", "cloudgoat.pub")
            modified = True
            
        # Replace ../cloudgoat with cloudgoat
        if "../cloudgoat" in new_content:
            new_content = new_content.replace("../cloudgoat", "cloudgoat")
            modified = True
            
        # Replace ../whitelist.txt with whitelist.txt
        if "../whitelist.txt" in new_content:
            new_content = new_content.replace("../whitelist.txt", "whitelist.txt")
            modified = True
            
        # Handle variables.tf defaults
        if 'variables.tf' in tf_file:
            var_blocks = get_hcl_blocks(new_content, "variable")
            for b in reversed(var_blocks):
                if b['name1'] == 'profile':
                    new_content = new_content[:b['start_idx']] + new_content[b['end_idx']:]
                    modified = True
                elif b['name1'] == 'region':
                    if 'default' in b['content']:
                        new_b = re.sub(r'default\s*=\s*"[^"]+"', 'default     = "us-east-1"', b['content'])
                        new_content = new_content[:b['start_idx']] + new_b + new_content[b['end_idx']:]
                    else:
                        insert_idx = b['content'].rfind('}')
                        new_b = b['content'][:insert_idx] + '  default = "us-east-1"\n' + b['content'][insert_idx:]
                        new_content = new_content[:b['start_idx']] + new_b + new_content[b['end_idx']:]
                    modified = True
                elif b['name1'] == 'cgid':
                    if 'default' not in b['content']:
                        insert_idx = b['content'].rfind('}')
                        new_b = b['content'][:insert_idx] + '  default = "lab"\n' + b['content'][insert_idx:]
                        new_content = new_content[:b['start_idx']] + new_b + new_content[b['end_idx']:]
                        modified = True
                elif b['name1'] == 'cg_whitelist':
                    if 'default' not in b['content']:
                        insert_idx = b['content'].rfind('}')
                        new_b = b['content'][:insert_idx] + '  default = ["0.0.0.0/0"]\n' + b['content'][insert_idx:]
                        new_content = new_content[:b['start_idx']] + new_b + new_content[b['end_idx']:]
                        modified = True
                        
        if modified:
            with open(tf_file, 'w') as f:
                f.write(new_content)
                
    # Generate SSH keys if needed
    if need_keys:
        key_path = os.path.join(tf_dir, "cloudgoat")
        if os.path.exists(key_path):
            os.remove(key_path)
        if os.path.exists(key_path + ".pub"):
            os.remove(key_path + ".pub")
        subprocess.run(["ssh-keygen", "-t", "rsa", "-N", "", "-f", key_path], capture_output=True)
        print("  Generated SSH keypair.")
        
    # Generate whitelist.txt if needed
    if need_whitelist:
        with open(os.path.join(tf_dir, "whitelist.txt"), "w") as f:
            f.write("0.0.0.0/0\n")
        print("  Generated whitelist.txt.")
        
    # Modify outputs to make sure credentials are not hidden by "sensitive = true"
    access_key_res = find_starting_access_key(tf_dir)
    out_files = glob.glob(os.path.join(tf_dir, "output*.tf"))
    for out_file in out_files:
        with open(out_file, 'r') as f:
            content = f.read()
        
        modified_out = False
        new_content = content
        
        # Find any pattern of aws_iam_access_key.xxx.secret and wrap it with nonsensitive() if not already wrapped
        pattern = re.compile(r'(?<!nonsensitive\()aws_iam_access_key\.([a-zA-Z0-9_-]+)\.secret')
        if pattern.search(new_content):
            new_content = pattern.sub(r'nonsensitive(aws_iam_access_key.\1.secret)', new_content)
            modified_out = True
            
        if 'sensitive' in new_content:
            new_content = re.sub(r'sensitive\s*=\s*true', 'sensitive = false', new_content)
            modified_out = True
            
        # Rename outputs for starting user credentials
        if access_key_res:
            blocks = get_hcl_blocks(new_content, "output")
            for b in reversed(blocks):
                if f"aws_iam_access_key.{access_key_res}.secret" in b['content']:
                    if b['name1'] != "secret_key":
                        new_content = new_content.replace(f'output "{b["name1"]}"', 'output "secret_key"')
                        modified_out = True
                elif f"aws_iam_access_key.{access_key_res}.id" in b['content'] or (f"aws_iam_access_key.{access_key_res}" in b['content'] and ".secret" not in b['content']):
                    if b['name1'] != "access_key":
                        new_content = new_content.replace(f'output "{b["name1"]}"', 'output "access_key"')
                        modified_out = True
            
        if modified_out:
            with open(out_file, 'w') as f:
                f.write(new_content)
                
    # Create main.tf (from provider.tf)
    provider_file = os.path.join(tf_dir, "provider.tf")
    if os.path.exists(provider_file):
        with open(provider_file, 'r') as f:
            prov_content = f.read()
        os.remove(provider_file)
    else:
        prov_content = ""
        
    # Overwrite profile and region in provider
    prov_content = re.sub(r'profile\s*=\s*var\.profile\s*\n', '', prov_content)
    prov_content = re.sub(r'region\s*=\s*var\.region\s*\n', 'region = "us-east-1"\n', prov_content)
    
    main_content = prov_content + "\n"
    
    main_file = os.path.join(tf_dir, "main.tf")
    with open(main_file, 'w') as f:
        f.write(main_content)
        
    # Format
    subprocess.run(["terraform", "fmt"], cwd=tf_dir, capture_output=True)
    
    # Zip
    zip_name = f"{os.path.basename(scenario_path)}.zip"
    zip_path = os.path.join(scenario_path, zip_name)
    if os.path.exists(zip_path):
        os.remove(zip_path)
        
    subprocess.run(["zip", "-r", f"../{zip_name}", "."], cwd=tf_dir, capture_output=True)
    
    # Cleanup copied assets and keys from git workspace to keep it clean
    if os.path.exists(dest_assets):
        shutil.rmtree(dest_assets)
    if need_keys:
        if os.path.exists(key_path):
            os.remove(key_path)
        if os.path.exists(key_path + ".pub"):
            os.remove(key_path + ".pub")
    if need_whitelist:
        wl_path = os.path.join(tf_dir, "whitelist.txt")
        if os.path.exists(wl_path):
            os.remove(wl_path)
            
    print("  Done.")
    return True

if __name__ == "__main__":
    success = 0
    failed = 0
    for scenario in os.listdir(AWS_DIR):
        path = os.path.join(AWS_DIR, scenario)
        if os.path.isdir(path):
            if process_scenario(path):
                success += 1
            else:
                failed += 1
                
    print(f"Success: {success}, Failed: {failed}")
