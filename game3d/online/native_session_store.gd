extends RefCounted
# App-private, device-bound encrypted storage. Not an Apple Keychain integration.
# Never part of exported village snapshots; never stores passwords.
var path="user://native-session.dat"
func key(create:bool) -> PackedByteArray:
 var salt=PackedByteArray();var key_path=path+".key"
 if FileAccess.file_exists(key_path):salt=FileAccess.get_file_as_bytes(key_path)
 elif create:
  salt=Crypto.new().generate_random_bytes(32)
  var f=FileAccess.open(key_path,FileAccess.WRITE)
  if f==null:return PackedByteArray()
  f.store_buffer(salt);f.flush();f.close();protect(key_path)
 if salt.size()!=32:return PackedByteArray()
 return (salt.hex_encode()+OS.get_unique_id()).sha256_buffer()
func protect(file:String):
 if OS.get_name()!="Windows":FileAccess.set_unix_permissions(file,384)
func save_session(value:Dictionary) -> bool:
 var secret=key(true)
 if secret.size()!=32:return false
 var temp=path+".tmp";var f=FileAccess.open_encrypted(temp,FileAccess.WRITE,secret)
 if f==null:return false
 f.store_string(JSON.stringify(value));f.close();protect(temp)
 return DirAccess.rename_absolute(temp,path)==OK
func load_session() -> Dictionary:
 if not FileAccess.file_exists(path):return {}
 var secret=key(false)
 if secret.size()!=32:return {}
 var f=FileAccess.open_encrypted(path,FileAccess.READ,secret)
 if f==null:return {}
 if f.get_length()>65536:f.close();return {}
 var value=JSON.parse_string(f.get_as_text());f.close()
 return value if value is Dictionary else {}
func clear():
 for suffix in ["",".tmp",".key"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
