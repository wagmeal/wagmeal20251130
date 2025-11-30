import re, pathlib

# リポジトリのルートを基準に再帰的に .swift を探す
root = pathlib.Path(".")
swift_files = [p for p in root.rglob("*.swift") if "DerivedData" not in str(p)]

views = set()
vms = set()
edges_view_vm = set()
edges_vm_collection = set()
firebase_files = {}  # file -> set of {"Firestore","Storage","Auth"}
collections_found = set()

# 型定義
re_view = re.compile(r'^\s*struct\s+(\w+)\s*:\s*View\b', re.M)
re_vm = re.compile(r'^\s*(?:final\s+)?class\s+(\w+)\s*:\s*ObservableObject\b', re.M)
re_actor_vm = re.compile(r'^\s*actor\s+(\w+)\s*:\s*ObservableObject\b', re.M)

# View が VM を持っているパターン
re_prop_vm = re.compile(r'@(?:StateObject|ObservedObject|EnvironmentObject)\s+var\s+\w+\s*:\s*(\w+)')
re_binding_vm = re.compile(r'@Binding\s+var\s+\w+\s*:\s*(\w+)(?:\??)\b')

# Firebase 関連
re_import_fs = re.compile(r'^\s*import\s+FirebaseFirestore(?:Swift)?\s*$', re.M)
re_import_storage = re.compile(r'^\s*import\s+FirebaseStorage\s*$', re.M)
re_import_auth = re.compile(r'^\s*import\s+FirebaseAuth\s*$', re.M)

re_use_fs = re.compile(r'Firestore\.firestore\(')
re_use_storage = re.compile(r'Storage\.storage\(')
re_use_auth = re.compile(r'Auth\.auth\(')

# Firestore collection
re_collection = re.compile(r'\.collection\s*\(\s*"([^"]+)"\s*\)')

def file_has(pattern, text):
    return bool(pattern.search(text))

for f in swift_files:
    txt = f.read_text(encoding="utf-8", errors="ignore")

    # View / ViewModel 抽出
    file_views = [m.group(1) for m in re_view.finditer(txt)]
    file_vms = [m.group(1) for m in re_vm.finditer(txt)] + [m.group(1) for m in re_actor_vm.finditer(txt)]

    views.update(file_views)
    vms.update(file_vms)

    # View -> VM
    for view_name in file_views:
        for m in re_prop_vm.finditer(txt):
            edges_view_vm.add((view_name, m.group(1)))
        for m in re_binding_vm.finditer(txt):
            btype = m.group(1)
            if btype in vms:
                edges_view_vm.add((view_name, btype))

    # どのファイルが Firebase を直接触っているか
    kinds = set()
    if file_has(re_import_fs, txt) or file_has(re_use_fs, txt):
        kinds.add("Firestore")
    if file_has(re_import_storage, txt) or file_has(re_use_storage, txt):
        kinds.add("Storage")
    if file_has(re_import_auth, txt) or file_has(re_use_auth, txt):
        kinds.add("Auth")
    if kinds:
        firebase_files[f.as_posix()] = kinds

    # VM -> collection
    if file_vms:
        cols = re_collection.findall(txt)
        for c in cols:
            collections_found.add(c)
            for vm_name in file_vms:
                edges_vm_collection.add((vm_name, c))

# ===== View -> ViewModel 図 =====
view_vm_mmd = []
view_vm_mmd.append("flowchart TB")
view_vm_mmd.append("  %% Views")
for v in sorted(views):
    view_vm_mmd.append(f"  {v}")
view_vm_mmd.append("  %% ViewModels")
for vm in sorted(vms):
    view_vm_mmd.append(f"  {vm}:::vm")
view_vm_mmd.append("  %% View -> ViewModel")
for a, b in sorted(edges_view_vm):
    view_vm_mmd.append(f"  {a} --> {b}")
view_vm_mmd.append("  classDef vm fill:#eef,stroke:#88f;")

# ===== Firebase を触るファイル図 =====
fb_mmd = []
fb_mmd.append("flowchart TB")
fb_mmd.append("  subgraph Firebase")
fb_mmd.append("    Firestore[(Firestore)]")
fb_mmd.append("    Storage[(Storage)]")
fb_mmd.append("    Auth[(Auth)]")
fb_mmd.append("  end")
for path, kinds in sorted(firebase_files.items()):
    node = re.sub(r'[^A-Za-z0-9_]', '_', path)
    fb_mmd.append(f"  {node}[\"{path}\"]")
    if "Firestore" in kinds:
        fb_mmd.append(f"  {node} --> Firestore")
    if "Storage" in kinds:
        fb_mmd.append(f"  {node} --> Storage")
    if "Auth" in kinds:
        fb_mmd.append(f"  {node} --> Auth")

# ===== ViewModel -> Firestore コレクション図 =====
vm_data_mmd = []
vm_data_mmd.append("flowchart LR")
if collections_found:
    vm_data_mmd.append("  subgraph Firestore")
    for c in sorted(collections_found):
        cn = re.sub(r'[^A-Za-z0-9_]', '_', c)
        vm_data_mmd.append(f"    {cn}((\"{c}\"))")
    vm_data_mmd.append("  end")
for vm, c in sorted(edges_vm_collection):
    cn = re.sub(r'[^A-Za-z0-9_]', '_', c)
    vm_data_mmd.append(f"  {vm} --> {cn}")

# ===== ファイル出力 =====
outdir = pathlib.Path("docs/architecture")
outdir.mkdir(parents=True, exist_ok=True)
(pathlib.Path("docs/architecture/view_vm.mmd")).write_text("\n".join(view_vm_mmd), encoding="utf-8")
(pathlib.Path("docs/architecture/firebase_files.mmd")).write_text("\n".join(fb_mmd), encoding="utf-8")
(pathlib.Path("docs/architecture/vm_collections.mmd")).write_text("\n".join(vm_data_mmd), encoding="utf-8")

print("Generated diagrams in docs/architecture/")