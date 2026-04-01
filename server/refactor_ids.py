import os
import re

def process_sql(file_path):
    try:
        with open(file_path, "r") as f:
            content = f.read()

        content = re.sub(r'UUID DEFAULT uuid_generate_v4\(\)', 'VARCHAR(7)', content)
        content = re.sub(r'UUID REFERENCES', 'VARCHAR(7) REFERENCES', content)
        content = re.sub(r'UUID\s', 'VARCHAR(7) ', content)
        
        with open(file_path, "w") as f:
            f.write(content)
        print(f"Updated {file_path}")
    except Exception as e:
        pass

process_sql("admin/supabase/schema.sql")

def process_ts_api(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".ts"):
                path = os.path.join(root, file)
                try:
                    with open(path, "r") as f:
                        lines = f.read()
                    
                    if "crypto.randomUUID()" in lines:
                        # Determine prefix loosely based on file name or 'x'
                        prefix = 'x'
                        if 'user' in path: prefix = 'u'
                        elif 'book' in path: prefix = 'b'
                        elif 'fine' in path: prefix = 'f'
                        elif 'loan' in path: prefix = 'l'

                        lines = lines.replace(
                            "crypto.randomUUID()", 
                            f"`{prefix}${{Math.floor(100000 + Math.random() * 900000)}}`"
                        )
                        with open(path, "w") as f:
                            f.write(lines)
                        print(f"Updated {path}")
                except Exception as e:
                    pass

process_ts_api("admin/app/api")
process_ts_api("admin/lib")

def process_python(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".py"):
                path = os.path.join(root, file)
                try:
                    with open(path, "r") as f:
                        content = f.read()
                    
                    if "uuid.uuid4()" in content:
                        prefix = 'x'
                        if 'user' in path: prefix = 'u'
                        elif 'loan' in path: prefix = 'l'
                        elif 'reserv' in path: prefix = 'r'
                        elif 'fine' in path: prefix = 'f'
                        
                        content = re.sub(
                            r'f"l\{.*?uuid4\(\).*?\}"',
                            f"f'{prefix}{{__import__(\"random\").randint(100000, 999999)}}'",
                            content
                        )
                        content = re.sub(
                            r'uuid\.uuid4\(\)\.hex',
                            f"f'{prefix}{{__import__(\"random\").randint(100000, 999999)}}'",
                            content
                        )
                        content = re.sub(
                            r'str\(uuid\.uuid4\(\)\)',
                            f"f'{prefix}{{__import__(\"random\").randint(100000, 999999)}}'",
                            content
                        )
                        
                        with open(path, "w") as f:
                            f.write(content)
                        print(f"Updated {path}")
                except Exception as e:
                    pass

process_python("server/app/routers")

print("Refactoring done.")
