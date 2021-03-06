%zewdMDWS	; EWD Open Source / Stateless implementation of MDWS
 ;
 ; Product: Enterprise Web Developer (Build 944)
 ; Build Date: Fri, 23 Nov 2012 17:15:07
 ; 
 ; ----------------------------------------------------------------------------
 ; | Enterprise Web Developer for GT.M and m_apache                           |
 ; | Copyright (c) 2004-12 M/Gateway Developments Ltd,                        |
 ; | Reigate, Surrey UK.                                                      |
 ; | All rights reserved.                                                     |
 ; |                                                                          |
 ; | http://www.mgateway.com                                                  |
 ; | Email: rtweed@mgateway.com                                               |
 ; |                                                                          |
 ; | This program is free software: you can redistribute it and/or modify     |
 ; | it under the terms of the GNU Affero General Public License as           |
 ; | published by the Free Software Foundation, either version 3 of the       |
 ; | License, or (at your option) any later version.                          |
 ; |                                                                          |
 ; | This program is distributed in the hope that it will be useful,          |
 ; | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
 ; | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            |
 ; | GNU Affero General Public License for more details.                      |
 ; |                                                                          |
 ; | You should have received a copy of the GNU Affero General Public License |
 ; | along with this program.  If not, see <http://www.gnu.org/licenses/>.    |
 ; ----------------------------------------------------------------------------
 ;
 ;QUIT
 ;
 ;
 ; Scripts used by openMDWS EWD Pages
 ;
getRequest(sessid)
 ;
 n contentType,cookie,docName,facade,func,method,ok,originalSessid,token,x
 ;
 s docName="mdws"_sessid
 d setSessionValue^%zewdAPI("docName",docName,sessid)
 s contentType=$$getRequestValue^%zewdAPI("contentType",sessid)
 i contentType="" s contentType="text/xml"
 d setSessionValue^%zewdAPI("contentType",contentType,sessid)
 ;
 s facade=$$getRequestValue^%zewdAPI("facade",sessid)
 i facade="" d noFacade(sessid,0) QUIT ""
 d setSessionValue^%zewdAPI("mdws.facade",facade,sessid)
 ;
 s method=$$getRequestValue^%zewdAPI("method",sessid)
 i method="" d noMethod(sessid,0) QUIT ""
 i $g(^zewd("trace"))=1 d trace^%zewdAPI("*** getRequest^%zewdMDWS: method="_method_"; facade="_facade)
 i method="connect" QUIT $$connect(sessid,0)
 ;
 s func=$g(^%zewd("openMDWS","mappings",facade,method,"MDWSWrapper"))
 i func="" d noFunc(method,sessid,0) QUIT ""
 s cookie=$$getServerValue^%zewdAPI("Cookie",sessid)
 i cookie="" s cookie=$$getServerValue^%zewdAPI("HTTP_COOKIE",sessid)
 i cookie="" d badCookie(sessid,0) QUIT ""
 s token=$p(cookie,"SessionId=",2)
 s token=$p(token,";",1)
 s originalSessid=$$getSessid^%zewdAPI(token)
 i originalSessid="" d badCookie(sessid,0) QUIT ""
 d setSessionValue^%zewdAPI("mdws_cookie",cookie,sessid)
 d setSessionValue^%zewdAPI("mdws.originalSessid",originalSessid,sessid)
 ;
 s x="s ok=$$"_func_"(sessid,0)"
 i $g(^zewd("trace"))=1 d trace^%zewdAPI("*** getRequest^%zewdMDWS: x="_x)
 x x
 QUIT ok
 ;
dispatch(facade,method,inputs,results)
 ;
 n func,ok,x
 ;
 s func=$g(^%zewd("openMDWS","mappings",facade,method,"coreMethod"))
 i func="" d  QUIT results("error")
 . s results("error")="Core RPC function not found for the openMDWS method: "_method_" ("_facade_" facade)"
 ;
 s x="s ok=$$"_func_"(.inputs,.results)"
 i $g(^zewd("trace"))=1 d trace^%zewdAPI("** dispatch^%zewdMDWS: x="_x)
 x x
 QUIT ok
 ;
invoke(method,localCall,results,originalSessid,sessid)
 ;
 n facade,inputs,ok
 ;
 k results
 d createInputs(localCall,.inputs,sessid)
 s facade=$$getSessionValue^%zewdAPI("mdws.facade",sessid)
 s originalSessid=$$getSessionValue^%zewdAPI("mdws.originalSessid",sessid)
 s ok=$$dispatch(facade,method,.inputs,.results)
 i ok'="" d  QUIT 0
 . s attrs("message")=ok
 . d createFault(.attrs,$g(localCall),sessid)
 QUIT 1
 ;
createOutput(localCall,array,sessid)
 ;
 n docName
 ;
 i '$d(array) d
 . n attrs,outerTag
 . s outerTag="DataSourceArray"
 . s attrs("message")="No output was created"
 . d outerTag(.array,"DataSourceArray",sessid)
 . s array(outerTag,"fault","type")=$g(attrs("type"))
 . s array(outerTag,"fault","message")=$g(attrs("message"))
 . s array(outerTag,"fault","stackTrace")=$g(attrs("type"))
 . s array(outerTag,"fault","suggestion")=$g(attrs("suggestion"))
 . s array(outerTag,"count")=0
 ;
 s docName=$$getSessionValue^%zewdAPI("docName",sessid)
 i $g(^zewd("trace"))=1 d trace^%zewdAPI("** createOutput^%zewdMDWS: docName="_docName_"; localCall="_localCall)
 i '$g(localCall) d
 . d outputAsXML(.array,docName)
 . i $$cloneDocument^%zewdDOM(docName,"testcopy")
 e  d
 . d deleteFromSession^%zewdAPI(docName,sessid)
 . d mergeArrayToSession^%zewdAPI(.array,docName,sessid)
 QUIT
 ;
outerTag(array,tagName,sessid)
 ;
 n facade
 ;
 s facade=$$getSessionValue^%zewdAPI("mdws.facade",sessid)
 s array(tagName,"xmlns")="http://mdws.medora.va.gov/"_facade_$c(1)_"attr"
 s array(tagName,"xmlns:xsd")="http://www.w3.org/2001/XMLSchema"_$c(1)_"attr"
 s array(tagName,"xmlns:xsi")="http://www.w3.org/2001/XMLSchema-instance"_$c(1)_"attr"
 QUIT
 ;
noMethod(sessid,localCall)
 ;
 n attrs
 ;
 s attrs("message")="openMDWS request did not specify a method"
 d createFault(.attrs,$g(localCall),sessid)
 QUIT
 ;
noFacade(sessid,localCall)
 ;
 n attrs
 ;
 s attrs("message")="openMDWS request did not specify a facade"
 d createFault(.attrs,$g(localCall),sessid)
 QUIT
 ;
noFunc(method,sessid,localCall)
 ;
 n attrs
 ;
 s attrs("message")="Back-end function for openMDWS method "_method_" could not be determined"
 d createFault(.attrs,$g(localCall),sessid)
 QUIT
 ;
badCookie(sessid,localCall)
 ;
 n attrs
 ;
 s attrs("message")="There is no connection to log onto: cookie missing or invalid"
 d createFault(.attrs,$g(localCall),sessid)
 QUIT
 ;
missingSitecode(sessid,localCall)
 ;
 n attrs,facade
 ;
 s attrs("message")="Missing sitecode"
 d createFault(.attrs,localCall,sessid)
 QUIT
 ;
createFault(attrs,localCall,sessid)
 ;
 n array,outerTag
 ;
 s sessid=+$g(sessid)
 s outerTag="DataSourceArray"
 d outerTag(.array,"DataSourceArray",sessid)
 s array(outerTag,"fault","type")=$g(attrs("type"))
 s array(outerTag,"fault","message")=$g(attrs("message"))
 s array(outerTag,"fault","stackTrace")=$g(attrs("type"))
 s array(outerTag,"fault","suggestion")=$g(attrs("suggestion"))
 s array(outerTag,"count")=0
 d createOutput^%zewdMDWS($g(localCall),.array,sessid)
 s cookie=$$getSessionValue^%zewdAPI("mdws_cookie",sessid)
 i cookie="" d setSessionValue^%zewdAPI("mdws_cookie","Missing Cookie",sessid)
 QUIT
 ;
createInputs(localCall,inputs,sessid)
 i $g(localCall) d
 . d mergeArrayFromSession^%zewdAPI(.inputs,"mdws_params",sessid)
 e  d
 . n name
 . s name=""
 . f  s name=$$getNextRequestName^%zewdAPI2(name,sessid) q:name=""  d
 . . s inputs(name)=$$getRequestValue^%zewdAPI(name,sessid)
 d deleteFromSession^%zewdAPI("mdws_params",sessid)
 QUIT
 ;
connect(sessid,localCall)
 ;
 ; GET: get.ewd?method=connect&sitelist=100
 ;
 n array,cookie,count,docName,facade,inputs,no,ok,outerTag,results
 ;
 s localCall=$g(localCall)
 i $g(^zewd("trace"))=1 d trace^%zewdAPI("*** connect^%zewdMDWS: invoked! localCall="_$d(localCall))
 s docName=$$getSessionValue^%zewdAPI("docName",sessid)
 d createInputs(localCall,.inputs,sessid)
 i $g(inputs("sitelist"))="" d missingSitecode(sessid,localCall) QUIT ""
 ;
 ; do some test/lookup on site list to confirm it exists
 ;
 s count=$l(inputs("sitelist"),",")
 s inputs("sessid")=sessid
 s facade=$$getSessionValue^%zewdAPI("mdws.facade",sessid)
 s ok=$$dispatch(facade,"connect",.inputs,.results)
 i $g(^zewd("trace"))=1 d trace^%zewdAPI("** connect^%zewdMDWS: finished dispatch^%zewdMDWS")
 ;
 i count=1 d setSessionValue^%zewdAPI("siteId",inputs("sitelist"),sessid)
 s outerTag="DataSourceArray"
 d outerTag^%zewdMDWS(.array,outerTag,sessid)
 s array(outerTag,"items","DataSourceTO","protocol")="VISTA"
 s array(outerTag,"items","DataSourceTO","modality")="HIS"
 s array(outerTag,"items","DataSourceTO","timeout")=0
 s array(outerTag,"items","DataSourceTO","port")="9100"
 s array(outerTag,"items","DataSourceTO","provider")="127.0.0.1"
 s array(outerTag,"items","DataSourceTO","status")="active"
 s array(outerTag,"items","DataSourceTO","description")=""
 s array(outerTag,"items","DataSourceTO","context")=""
 s array(outerTag,"items","DataSourceTO","testSource")="false"
 s array(outerTag,"items","DataSourceTO","vendor")=""
 s array(outerTag,"items","DataSourceTO","version")=""
 s array(outerTag,"items","DataSourceTO","siteId","tag")=$p(inputs("sitelist"),",",1)
 s array(outerTag,"items","DataSourceTO","siteId","text")="dEWDrop"
 s array(outerTag,"items","DataSourceTO","ewdToken")=$g(results("token"))
 i '$d(results("message")) d
 . s array(outerTag,"items","DataSourceTO","welcomeMessage")=""_$c(1)
 e  d
 . s no=""
 . f  s no=$o(results("message",no)) q:no=""  d
 . . s array(outerTag,"items","DataSourceTO","welcomeMessage","#text",0)=no
 . . s array(outerTag,"items","DataSourceTO","welcomeMessage","#text",no)=results("message",no)
 d createOutput^%zewdMDWS($g(localCall),.array,sessid)
 ;
 s cookie="ASP.NET_SessionId="_$g(results("token"))_"; path=/; HttpOnly"
 d setSessionValue^%zewdAPI("mdws.cookie",cookie,sessid)
 d setSessionValue^%zewdAPI("mdws.token",$g(results("token")),sessid)
 ;
 QUIT ""
 ;
outputContent(sessid)
 ;
 n contentType,docName,gloRef,io,ok
 ;
 s docName=$$getSessionValue^%zewdAPI("docName",sessid)
 s contentType=$$getSessionValue^%zewdAPI("contentType",sessid)
 i contentType="text/xml" d
 . i $$getSessionValue^%zewdAPI("ewd_technology",sessid)="node" d
 . . d outputDOMToGlobal(docName)
 . e  d
 . . s ok=$$outputDOM^%zewdDOM(docName,1,1)
 . s ok=$$removeDocument^%zewdDOM(docName)
 ;
 QUIT
 ;
outputAsXML(array,docName)
 ;
 n deOID,docOID,subArray,tagName
 ;
 s tagName=$o(array(""))
 ;
 s docOID=$$newXMLDocument^%zewdDOM(docName,tagName,1)
 s deOID=$$getDocumentElement^%zewdDOM(docName)
 ;
 m subArray=array(tagName)
 d outputSubArrayAsXML(.subArray,deOID)
 QUIT
 ;
outputSubArrayAsXML(array,parentOID)
 ;
 n name
 ;
 s name=""
 f  s name=$o(array(name)) q:name=""  d
 . i name="#text" d  q
 . . n no,text,textOID
 . . s no=0
 . . f  s no=$o(array(name,no)) q:no=""  d
 . . . s text=$e(array(name,no),1,100)
 . . . s text=$$replaceAll^%zewdAPI(text,"<","&lt;")
 . . . s text=$$replaceAll^%zewdAPI(text,">","&gt;")
 . . . s textOID=$$createTextNode^%zewdDOM(text,docOID)
 . . . s textOID=$$appendChild^%zewdDOM(textOID,parentOID)
 . i name?1N.N d
 . . n subArray
 . . m subArray=array(name)
 . . d outputSubArrayAsXML(.subArray,parentOID)
 . e  d
 . . n dd
 . . s dd=$d(array(name))
 . . i dd=1 d  q
 . . . ; text or attribute node
 . . . n type,value
 . . . s value=array(name)
 . . . s type=$p(value,$c(1),2)
 . . . i type="" s type="text"
 . . . s value=$p(value,$c(1),1)
 . . . i type="text" d
 . . . . n newOID
 . . . . s newOID=$$addElementToDOM^%zewdDOM(name,parentOID,,,value)
 . . . i type="attr" d setAttribute^%zewdDOM(name,value,parentOID)
 . . i dd=10 d  q
 . . . ; intermediate node
 . . . n newOID,subArray
 . . . s newOID=$$addElementToDOM^%zewdDOM(name,parentOID)
 . . . m subArray=array(name)
 . . . d outputSubArrayAsXML(.subArray,newOID)
 QUIT
 ;
outputDOMToGlobal(nodeOID)
 ;
 i nodeOID'?1N.N1"-"1N.N s nodeOID=$$getDocumentNode^%zewdDOM(nodeOID)
 i $g(nodeOID)="" QUIT
 i '$$nodeExists^%zewdDOM(nodeOID) QUIT
 ;k ^CacheTempXML($j)
 s ^CacheTempBuffer($j,$increment(^CacheTempBuffer($j)))="<?xml version='1.0' encoding='UTF-8' ?>"
 d outputNodeToGlobal(nodeOID)
 QUIT
 ;
outputNodeToGlobal(nodeOID)
 ;
 n nodeType
 ;
 s nodeType=$$getNodeType^%zewdDOM(nodeOID)
 i nodeType=9 d
 . n childOID
 . s childOID=$$getFirstChild^%zewdDOM(nodeOID)
 . i childOID'="" d outputNodeToGlobal(childOID)
 ;
 i nodeType=7 d
 . n childOID
 . s childOID=$$getNextSibling^%zewdDOM(nodeOID)
 . i childOID'="" d outputNodeToGlobal(childOID)
 ;
 i nodeType=1 d
 . n attrName,attrs,childOID,childTagName,comma,count,no,noOfInstances,ok,tag
 . n siblingOID,tagName,text,textArray
 . s tagName=$$getTagName^%zewdDOM(nodeOID)
 . s tag="<"_tagName
 . d getAttributeValues^%zewdDOM(nodeOID,.attrs)
 . s attrName=""
 . f  s attrName=$o(attrs(attrName)) q:attrName=""  d
 . . s tag=tag_" "_attrName_"="""_attrs(attrName)_""""
 . ;s tag=tag_">"
 . s text=$$getElementText^%zewdDOM(nodeOID,.textArray)
 . i text'="***Array",text="",$$hasChildNodes^%zewdDOM(nodeOID)="false" d  q
 . . s ^CacheTempBuffer($j,$increment(^CacheTempBuffer($j)))=tag_" />"
 . e  d
 . . s ^CacheTempBuffer($j,$increment(^CacheTempBuffer($j)))=tag_">"
 . i text'="***Array***",text'="" d
 . . s ^CacheTempBuffer($j,$increment(^CacheTempBuffer($j)))=text
 . e  d
 . . n lineNo
 . . s lineNo=""
 . . f  s lineNo=$o(textArray(lineNo)) q:lineNo=""  d
 . . . s ^CacheTempBuffer($j,$increment(^CacheTempBuffer($j)))=textArray(lineNo)
 . ; see if any child nodes are repeating
 . s childOID=""
 . f  d  q:childOID=""
 . . s childOID=$$getNextChild^%zewdDOM(nodeOID,childOID)
 . . q:childOID=""
 . . q:$$getNodeType^%zewdDOM(childOID)'=1
 . . d outputNodeToGlobal(childOID)
 . s ^CacheTempBuffer($j,$increment(^CacheTempBuffer($j)))="</"_tagName_">"
 ;
 QUIT
 ;
install
 ;
 n arr,facade,line,lineNo,ok,operation,tagName
 ;
 k ^%zewd("openMDWS","mappings")
 m ^%zewd("openMDWS","mappings")=^zewd("openMDWS","userDefined")
 f lineNo=1:1 s line=$t(mappings+lineNo^%zewdMDWSMap) q:line["***END***"  d
 . s line=$p(line,";;",2,200)
 . s ok=$$parseJSON^%zewdJSON(line,.arr,1)
 . s facade=$g(arr("facade")) k arr("facade")
 . s operation=$g(arr("operation")) k arr("operation")
 . m ^%zewd("openMDWS","mappings",facade,operation)=arr
 QUIT
 ;
