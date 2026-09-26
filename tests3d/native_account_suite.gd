extends SceneTree
const Form=preload("res://game3d/ui/native_account_form.gd")
class TestGame extends "res://game3d/main.gd":
 var submitted={}
 func authenticate(email:String,password:String,register:bool):submitted={"email":email,"password":password,"register":register}
var failed=0
var checks=0
func check(ok:bool,message:String):
 checks+=1
 if not ok:failed+=1;push_error(message)
func _initialize():call_deferred("run")
func run():
 var g=TestGame.new();g.require_login=true;g.save_path="user://qa-native-login.json";root.add_child(g)
 await process_frame;await process_frame
 var form=Form.new();g.modal.add_child(form);form.configure(g,Vector2(860,536))
 await process_frame
 check(g.auth_locked() and not g.world.visible,"native account gate hides unloaded village")
 check(form.email.virtual_keyboard_type==LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS,"email keyboard selected")
 check(form.password.secret and form.password.virtual_keyboard_type==LineEdit.KEYBOARD_TYPE_PASSWORD,"password masked with password keyboard")
 check(form.follow_focus,"keyboard focus follows scrolling")
 check(form.available_height(0,390,100,.54)==form.base_height,"full form height without keyboard")
 check(form.available_height(200,390,100,.54)<form.base_height,"form shrinks above keyboard")
 check(form.available_height(800,390,100,.54)>=70,"scroll remains usable on very small screen")
 form.email.text="native@example.test";form.password.text="Test-password-123";form.password.text_submitted.emit(form.password.text)
 check(g.submitted.get("email")==form.email.text and not g.submitted.get("register",true),"native keyboard submit forwards login")
 check(not FileAccess.file_exists(g.save_path),"locked native form does not overwrite saves")
 g.queue_free();await process_frame
 print("NATIVE_ACCOUNT_TESTS ",checks-failed,"/",checks);quit(1 if failed else 0)
