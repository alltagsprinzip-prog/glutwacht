extends RefCounted
const ORIGIN="https://glutwacht-spieltest.mg-automobile24.chatgpt.site"
static func tag(value:String) -> String:
 var target=value.strip_edges().to_upper().trim_prefix("#")
 if value.strip_edges().begins_with(ORIGIN+"/"):
  target=""
  var query=value.split("?",true,1)
  if query.size()==2:
   for pair in query[1].split("#")[0].split("&"):
    if pair.begins_with("invite="):target=pair.substr(7).to_upper()
 return target if target.length()==12 and target.is_valid_hex_number() else ""
static func url(value:String) -> String:
 var target=tag(value)
 return ORIGIN+"/v08/?invite="+target if target!="" else ""
static func pending() -> String:
 if not OS.has_feature("web"):return ""
 return tag(str(JavaScriptBridge.eval("window.GlutwachtInvite?.peek()||''",true)))
static func clear():
 if OS.has_feature("web"):JavaScriptBridge.eval("window.GlutwachtInvite?.clear()")
