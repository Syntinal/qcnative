%%
%% Copyright 2007 Lee S. Barney
		
 %% Permission is hereby granted, free of charge, to any person obtaining a 
 %% copy of this software and associated documentation files (the "Software"), 
 %% to deal in the Software without restriction, including without limitation the 
 %% rights to use, copy, modify, merge, publish, distribute, sublicense, 
 %% and/or sell copies of the Software, and to permit persons to whom the Software 
 %% is furnished to do so, subject to the following conditions:
 
 %% The above copyright notice and this permission notice shall be 
 %% included in all copies or substantial portions of the Software.
 
 
 %% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 %% INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
 %% PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
 %% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
 %% CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
 %% OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%
-module(utilities).

%%
%% Include files
%%
-record(session_data, {id}).
-include("../include/yaws_api.hrl").

%%
%% Exported Functions
%%
-export([map_security/4, map_command/6, create_GUID/1, 
         get_session_user_id/1, 
         set_session_user_id/1, add_html_message/2, add_html_message/1,
         add_session_cookie/2, add_session_cookie/1,
         add_cookie/3, add_cookie/2, add_header/3, add_header/2]).

%%
%% API Functions
%%

%%
%% adds a key/value pair to the orig_map where the key is the command and the value is a tuple containing the
%% security module and the scf.  It then returns the new map generated by the addition
%%
map_security(_Command, _Security_module, _Security_control_function, _Orig_map) -> 
    
    Amapping = {sec_mapping,{_Security_module, _Security_control_function}},
    %% use append instead of store since a command can have a list of mappings
    dict:append(_Command, Amapping, _Orig_map). 


%%
%% adds a key/value pair to the orig_map where the key is the command and the value is a tuple containing the
%% brule module, the business rule function, the vcf module, and the vcf.  It then returns the new map generated by the addition
%%
map_command(_Command, _B_rule_module, _B_rule_function, _Vcf_module, _View_control_function, _Orig_map) -> 
    
    Amapping = {cmd_mapping,{_B_rule_module, _B_rule_function, _Vcf_module, _View_control_function}},
    dict:store(_Command, Amapping, _Orig_map).                                       


%%
%% Creates a Globally Unique ID based on data found in the Request
%%
create_GUID(_Request) ->
    %% the now function guarantees no two calls will return the same value.  See erlang:now() API
	{guid,{_Request#arg.client_ip_port, erlang:now()}}.

%%
%%
%%

get_session_user_id(_Request)->
    Headers = _Request#arg.headers,
    Cookies = Headers#headers.cookie,
    Cookie = yaws_api:find_cookie_val("qc_session", Cookies),
    {Success, Session_data} = yaws_api:cookieval_to_opaque(Cookie),
    if
    	Cookie == [] orelse Success =/= ok ->
            Ret_val = false;
        true -> Ret_val = Session_data#session_data.id
    end,
    
    Ret_val.

%%
%%
%%   
 set_session_user_id(_Id) ->
     Session_data = #session_data{id = _Id},
                  Cookie = yaws_api:new_cookie_session(Session_data),
     
     Cookie. 

%%
%%
%%
add_html_message(Message) ->
    add_html_message([], Message).

add_html_message(Results, Message) ->
    lists:append(Results, [{html,Message}]).

%%
%%
%%
add_session_cookie(ID)->
    add_session_cookie([], ID).

add_session_cookie(Results, ID) ->
    Value = set_session_user_id(ID),
    lists:append(Results, [{header, "Set-Cookie: qc_session="++Value++";path=/;"}]). 

%%
%%
%%
add_cookie( Name, Value) ->
	add_cookie([], Name, Value).

add_cookie(Results, Name, Value) ->
    lists:append(Results, [{header, "Set-Cookie: "++Name++"="++Value++";path=/;"}]).

%%
%%
%%
add_header(Name, Value) ->
    add_header([], Name, Value).

add_header(Results, Name, Value) ->
    lists:append(Results, [{header, "HTTP-header: "++Name++"="++Value++";path=/;"}]).
%%
%% Local Functions
%%

