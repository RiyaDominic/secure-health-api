import os, json, uuid
from cryptography.fernet import Fernet

KEY_FILE = os.environ.get('APP_DATA_KEY', 'keys/data.key')
DATA_DIR = 'data'

def _key():
    with open(KEY_FILE, 'rb') as f:
        return f.read()

def _cipher():
    return Fernet(_key())

def save_record(obj):
    os.makedirs(DATA_DIR, exist_ok=True)
    pid = obj.get('patient_id') or str(uuid.uuid4())
    data = json.dumps(obj).encode('utf-8')
    enc = _cipher().encrypt(data)
    with open(os.path.join(DATA_DIR, f'{pid}.bin'), 'wb') as f:
        f.write(enc)
    return pid

def get_record(pid):
    try:
        with open(os.path.join(DATA_DIR, f'{pid}.bin'), 'rb') as f:
            enc = f.read()
        dec = _cipher().decrypt(enc)
        return json.loads(dec.decode('utf-8'))
    except FileNotFoundError:
        return None

def get_all_records():
    os.makedirs(DATA_DIR, exist_ok=True)
    records = []
    try:
        for filename in os.listdir(DATA_DIR):
            if filename.endswith('.bin'):
                pid = filename.replace('.bin', '')
                try:
                    with open(os.path.join(DATA_DIR, filename), 'rb') as f:
                        enc = f.read()
                    dec = _cipher().decrypt(enc)
                    record = json.loads(dec.decode('utf-8'))
                    records.append(record)
                except Exception as e:
                    print(f"Error reading record {pid}: {e}")
                    continue
    except FileNotFoundError:
        pass
    return records