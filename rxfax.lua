
-- fetch a couple of channel variables needed to get started.
uuid                 = session:getVariable("uuid")
caller_id_number     = session:getVariable("caller_id_number")
destination_number   = session:getVariable("destination_number")


-- console notification that we're taking a call.
freeswitch.consoleLog("info","fsfax: " .. uuid .. ": Taking call from " .. caller_id_number .. " for " .. destination_number .. "\n")


local dbh = freeswitch.Dbh("sqlite://fsfax")  -- /var/lib/freeswitch/db/fsfax.db
assert(dbh:connected()) -- exits the script if we didn't connect properly


-- Query DB for settings to use for this call
query = "SELECT key, value FROM fsfax_config "
..      "WHERE type='session' "
..      "AND ( "
..      "      (match_key='*'   AND match_value='*' ) "
..      "   OR (match_key='DID' AND match_value='" .. destination_number .. "') " 
..      "   OR (match_key='CID' AND match_value='" .. caller_id_number .. "') "
..      "    ) "
..      "order by match_key, match_value, type, key, rank"


dbh:query(query, 
	function(row)
	freeswitch.consoleLog("info","fsfax: setting session key " .. row.key .. " => " .. row.value .. "\n")
		session:setVariable(row.key, row.value)
	end)


-- Query DB for DID routing
dbh:query("SELECT * FROM fsfax_route where did='" .. destination_number .. "'", 
	function(row)
		emailto = row.emailto
	end)

-- If no route found then exit without
-- answering the call.
-- Maybe this could be controled via a setting
-- to allow a generic route for non-configured DIDs
if (emailto == nil) then
	return
end




-- lets take the call and attempt to receive the fax.
local fsfax_answered_time = os.time()
session:answer()
session:execute("spandsp_start_fax_detect", "set 'faxdetected=true'")

local done = false;
local count = 0;
local listen = 6; -- number of seconds to listen for a fax.

while done == false do
	count = count+1
	session:execute("playback", "silence_stream://500")

	if (session:getVariable('faxdetected') ~= nil) then
		done = true;
	end

	if (count >= 2*listen) then
		done = true;
	end
end
session:execute("rxfax", "/tmp/FAX-" .. uuid .. ".tif")
session:hangup()
local fsfax_hangup_time =  os.time();
local fsfax_call_duration = fsfax_hangup_time - fsfax_answered_time;


--[[
*****************************************************************************
Now the that the fax call is finished we will gather up a bunch of variables 
and send out an e-mail notification then log the fax call.
]]



-- http://wiki.freeswitch.org/wiki/Channel_Variables
caller_id_name       = session:getVariable("caller_id_name")
context              = session:getVariable("context");
network_addr         = session:getVariable("network_addr");
ani                  = session:getVariable("ani");
aniii                = session:getVariable("aniii");
rdnis                = session:getVariable("rdnis");
source               = session:getVariable("source");
chan_name            = session:getVariable("chan_name");
created_time         = session:getVariable("created_time");

ignore_early_media   = session:getVariable("ignore_early_media"); 
if (ignore_early_media == nil) then ignore_early_media = ''; end

-- wiki.freeswitch.org/wiki/Mod_spandsp
t38_leg = session:getVariable("t38_leg");
if (t38_leg == nil) then t38_leg = ''; end

fax_bad_rows = session:getVariable("fax_bad_rows")
if (fax_bad_rows == nil) then fax_bad_rows = ''; end

fax_document_total_pages = session:getVariable("fax_document_total_pages")
if (fax_document_total_pages == nil) then fax_document_total_pages = ''; end

fax_document_transferred_pages = session:getVariable("fax_document_transferred_pages")
if (fax_document_transferred_pages == nil) then fax_document_transferred_pages = ''; end

fax_ecm_requested = session:getVariable("fax_ecm_requested") 
if (fax_ecm_requested == nil) then fax_ecm_requested = ''; end

fax_ecm_used = session:getVariable("fax_ecm_used")
if (fax_ecm_used == nil) then fax_ecm_used = ''; end

fax_filename = session:getVariable("fax_filename")
if (fax_filename == nil) then fax_filename = ''; end

fax_image_resolution = session:getVariable("fax_image_resolution")
if (fax_image_resolution == nil) then fax_image_resolution = ''; end

fax_image_size = session:getVariable("fax_image_size")
if (fax_image_size == nil) then fax_image_size = ''; end

fax_local_station_id = session:getVariable("fax_local_station_id")
if (fax_local_station_id == nil) then fax_local_station_id = ''; end

fax_result_code = session:getVariable("fax_result_code")
if (fax_result_code == nil) then fax_result_code = ''; end

fax_result_text = session:getVariable("fax_result_text")
if (fax_result_text == nil) then fax_result_text = ''; end

fax_remote_station_id = session:getVariable("fax_remote_station_id")
if (fax_remote_station_id == nil) then fax_remote_station_id = ''; end

fax_success = session:getVariable("fax_success")
if (fax_success == nil) then fax_success = ''; end

fax_transfer_rate = session:getVariable("fax_transfer_rate")
if (fax_transfer_rate == nil) then fax_transfer_rate  = ''; end

fax_v17_disabled = session:getVariable("fax_v17_disabled")
if (fax_v17_disabled == nil) then fax_v17_disabled = ''; end

jitterbuffer_msec = session:getVariable("jitterbuffer_msec") 
if (jitterbuffer_msec == nil) then jitterbuffer_msec = ''; end

rtp_autoflush_during_bridge = session:getVariable("rtp_autoflush_during_bridge") 
if (rtp_autoflush_during_bridge == nil) then rtp_autoflush_during_bridge = ''; end

t38_gateway_format = session:getVariable("t38_gateway_format") 
if (t38_gateway_format == nil) then t38_gateway_format = ''; end

t38_peer = session:getVariable("t38_peer");  
if (t38_peer == nil) then t38_peer = ''; end

t38_trace_read = session:getVariable("t38_trace_read"); 
if (t38_trace_read == nil) then t38_trace_read = ''; end



to      = emailto
from    = caller_id_name .. "<" .. caller_id_number .. "@bmts.us>"
body     = "\n\n\n\n---\n"
..         "DETAILED FAX INFORMATION:\n"
..         "Remote Station ID  :" .. fax_remote_station_id .. "\n"
..         "CallerID Number    :" .. caller_id_number .. "\n"
..         "CallerID Name      :" .. caller_id_name .. "\n"
..         "Call UUID          :" .. uuid .. "\n"
..         "Call ID            :" .. session:getVariable("sip_call_id") .. "\n"

filepath = "/tmp/";
filebase = "FAX-" .. uuid;
filetiff = filepath .. filebase .. ".tif"
filepdf  = filepath .. filebase .. ".pdf"



function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

if (file_exists(filetiff)) then
	cmd = "tiff2pdf -z -o " .. filepdf .. " " .. filetiff;
	freeswitch.consoleLog("info","fsfax: tiff2pdf command: " .. cmd);
	os.execute(cmd);
	attach = filepdf;
else
	attach = nil;
end


if (attach) then

	subject = "[FAX] Recieved "
	if (fax_success == '0') then
		subject = subject .. "with errors, "
	end
	
	subject = subject .. fax_result_text .. ", " .. fax_document_total_pages .." Page(s), from " .. caller_id_name .. " " .. fax_remote_station_id;

	headers = "From: "     .. from .. "\n" ..
        	  "To: " .. to .. "\n"  ..
	          "Reply-To: " .. from .. "\n"  ..
	          "Subject: "  .. subject .. "\n" 

	body     = "Your fax is attached to this e-mail.\n" .. body
	freeswitch.consoleLog("info","fsfax: SENDING EMAIL WITH ATTACHMENT")
	email = freeswitch.email(to, from, headers, body, attach)
else
	if (session:getVariable("faxdetected") == nil) then
		if (fax_result_text == '') then fax_result_text = "Disconnected before fax tone" end
		if (fax_result_code == '') then fax_result_code = 99 end

		fax_result_text = "Possible Voice Caller, " .. fax_result_text
		fax_result_code = -fax_result_code
	end

	subject = "[FAX] Recieve Failure, " .. fax_result_text .. ", " .. fax_document_total_pages .." Page(s), from " .. caller_id_name .. " " .. fax_remote_station_id;


	headers = "From: "     .. from .. "\n" ..
        	  "To: " .. to .. "\n"  ..
	          "Reply-To: " .. from .. "\n"  ..
        	  "Subject: "  .. subject .. "\n" 


	body     = "We're sorry but we were unable to receive any fax data from the caller..\n" .. body
	freeswitch.consoleLog("info","fsfax: SENDING EMAIL -WITHOUT- ATTACHMENT")
	email = freeswitch.email(to, from, headers, body)
end


if (email == true) then
email = "1"
else
email = "0"
end

logQuery = "INSERT INTO fsfax_log (uuid"
..	   ", type, user, email, emailto, destination_number"
..         ", caller_id_number, caller_id_name, context, network_addr, ani"
..         ", aniii, rdnis, source, chan_name, created_time"
..         ", answered_time, hangup_time, ignore_early_media, t38_leg, fax_bad_rows"
..         ", fax_document_total_pages, fax_document_transferred_pages, fax_ecm_requested, fax_ecm_used, fax_filename"
..         ",fax_image_resolution,fax_image_size,fax_local_station_id,fax_result_code,fax_result_text"
..         ",fax_remote_station_id,fax_success,fax_transfer_rate,fax_v17_disabled,jitterbuffer_msec"
..         ",rtp_autoflush_during_bridge,t38_gateway_format,t38_peer,t38_trace_read"
..         ") " 

..         "VALUES ('" .. uuid .. "'"
..         ", 'RX', '', '" .. email .. "', '" .. emailto .. "', '" .. destination_number .. "'"
..         ", '" .. caller_id_number .. "', '" .. caller_id_name .. "', '" .. context .. "', '" .. network_addr .. "', '" .. ani .. "'"
..         ", '" .. aniii .. "', '" .. rdnis .. "', '" .. source .. "', '" .. chan_name .. "', '" .. created_time .. "'"
..         ", '" .. fsfax_answered_time .. "', '" .. fsfax_hangup_time .. "', '" .. ignore_early_media .. "', '" .. t38_leg .. "', '" .. fax_bad_rows .. "'"
..         ", '" .. fax_document_total_pages .. "', '" .. fax_document_transferred_pages .. "', '" .. fax_ecm_requested .. "', '" .. fax_ecm_used .. "', '" .. fax_filename .. "'"
..         ", '" .. fax_image_resolution .. "', '" .. fax_image_size .. "', '" .. fax_local_station_id .. "', '" .. fax_result_code .. "', '" .. fax_result_text .. "'"
..         ", '" .. fax_remote_station_id .. "', '" .. fax_success .. "', '" .. fax_transfer_rate .. "', '" .. fax_v17_disabled .. "', '" .. jitterbuffer_msec .. "'"
..         ", '" .. rtp_autoflush_during_bridge .. "', '" .. t38_gateway_format .. "', '" .. t38_peer .. "', '" .. t38_trace_read .. "'"
..         ");"

freeswitch.consoleLog("info","fsfax: logQuery: " .. logQuery);

dbh:query(logQuery);

dbh:release();

os.execute("grep " .. uuid .. " /var/log/freeswitch/freeswitch.log > /tmp/FAX-" .. uuid .. ".log")
freeswitch.consoleLog("info","fsfax: " .. email .. ": Finished Taking call from " .. caller_id_number .. " for " .. destination_number .. "\n")
