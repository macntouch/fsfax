local dbh = freeswitch.Dbh("sqlite://fsfax") 
assert(dbh:connected()) -- exits the script if we didn't connect properly
-- PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF; PRAGMA count_changes=OFF


if (argv[1] == nil) then
	stream:write("\n"
	..	"FreeSWITCH FAX v0.0 by Bruce Marriner <bruce@bmts.us>\n" 
	..	"Copyright 2014 by BMT Solutions. All rights reserved.\n" 
	..	"Usage: fax [category] [command] [arguments]\n"
	..	"stats         - \n"
	..	"init          - \n"
	..	"database      - database related functions\n"
	..	"route         - manage fax routing\n"
	..	"** Please note, the api is likely to change A LOT ** \n"
	..	"\n");
	return;
end


if (argv[1] == "stats") then
	local pages = 0
	local faxes = 0
	local success = 0
	local failure = 0
	local duration = 0

	dbh:query("SELECT * FROM fsfax_log", 
		function(row)
			faxes = faxes + 1;

			if (row.answered_time ~= "" and row.hangup_time ~= "") then
				duration = duration + (row.hangup_time - row.answered_time)
			end

			if (row.fax_document_total_pages ~= "") then
				pages = pages + row.fax_document_total_pages;
			end

			if (row.fax_result_code ~= "0") then
				failure = failure + 1;
			else
				success = success + 1;
			end
		end)

	stream:write(string.format("%14s : %d\n", "Total Duration", duration))
	stream:write(string.format("%14s : %d (%d%%)\n", "Total Success", success, success*100/failure-100))
	stream:write(string.format("%14s : %d (%d%%)\n", "Total Failure", failure, failure*100/success))
	stream:write(string.format("%14s : %d\n", "Total Faxes", faxes))
	stream:write(string.format("%14s : %d\n", "Total Pages", pages))
	return;
end


if (argv[1] == "init") then

	if (argv[2] == nil) then
		stream:write("fax init [all, alias, complete]")
	end
	
	if (argv[2] == "alias" or argv[2] == "all") then
		api = freeswitch.API();
		api:executeString("alias add fax lua fsfax/faxctl.lua");
	end

	if (argv[2] == "complete" or argv[2] == "all") then
		api = freeswitch.API();
		api:executeString("complete add fax");

		api:executeString("complete add fax stats");

		api:executeString("complete add fax init");
		api:executeString("complete add fax init complete");
		api:executeString("complete add fax init database");
		api:executeString("complete add fax init all");

		api:executeString("complete add fax build");
		api:executeString("complete add fax build route");
		api:executeString("complete add fax build config");
		api:executeString("complete add fax build log");
		api:executeString("complete add fax build modes");
		api:executeString("complete add fax build all");

		api:executeString("complete add fax clear");
		api:executeString("complete add fax clear route");
		api:executeString("complete add fax clear config");
		api:executeString("complete add fax clear log");
		api:executeString("complete add fax clear modes");
		api:executeString("complete add fax clear all");

		api:executeString("complete add fax route");
		api:executeString("complete add fax route add");
		api:executeString("complete add fax route del");
		api:executeString("complete add fax route update");
		api:executeString("complete add fax route show");

	end
	return;
end


if (argv[1] == "build") then

	if (argv[2] == nil) then
		stream:write("fax build [all, route, config, log, modes]")
	end

	query = ""

	if (argv[2] == "route" or argv[2] == "all") then
		query = "CREATE TABLE IF NOT EXISTS fsfax_route  (did INTEGER, emailto TEXT); \n"
		..	"CREATE UNIQUE INDEX routedid ON fsfax_route (did); \n"
		..	"INSERT INTO fsfax_route (did, emailto) VALUES ('19188945803','bruce@sqls.net'); \n" -- TEMP
		..	"INSERT INTO fsfax_route (did, emailto) VALUES ('19184936373','dbarnes@tulsacoxmail.com,lbarnes@tulsacoxmail.com,smalltown@tulsacoxmail.com,bruce@bmts.us'); \n" -- TEMP
	
	end

	if (argv[2] == "settings" or argv[2] == "all") then
		query = query 
		 ..	"CREATE TABLE IF NOT EXISTS fsfax_settings (id PRIMARY KEY, type, key, value, description); \n"
	end

	if (argv[2] == "config" or argv[2] == "all") then
		query = query 
		 ..	"CREATE TABLE IF NOT EXISTS fsfax_config (id PRIMARY KEY, type, key, value, description); \n"
	end

	if (argv[2] == "log" or argv[2] == "all") then
		query = query 
		..	"CREATE TABLE IF NOT EXISTS fsfax_log (uuid,type,user,email,emailto,destination_number,caller_id_number,caller_id_name,context,network_addr,ani,aniii,rdnis,source,chan_name,created_time,answered_time,hangup_time,ignore_early_media,t38_leg,fax_bad_rows,fax_document_total_pages,fax_document_transferred_pages,fax_ecm_requested,fax_ecm_used,fax_filename,fax_image_resolution,fax_image_size,fax_local_station_id,fax_result_code,fax_result_text,fax_remote_station_id,fax_success,fax_transfer_rate,fax_v17_disabled,jitterbuffer_msec,rtp_autoflush_during_bridge,t38_gateway_format,t38_peer,t38_trace_read); \n"
		..	"CREATE UNIQUE INDEX loguuid ON fsfax_log (uuid); \n"
	end

	if (query ~= "") then	
		query = "BEGIN EXCLUSIVE TRANSACTION; \n"
		..	query
		..	"COMMIT TRANSACTION; \n"
		stream:write(query);
		dbh:query(query)
	end
	return;
end

if (argv[1] == "clear") then

	if (argv[2] == nil) then
		stream:write("clear what?")
	end

	query = ""

	if (argv[2] == "route" or argv[2] == "all") then
--	query = "DROP TABLE IF EXISTS fsfax_route;\n"
	end

	if (argv[2] == "settings" or argv[2] == "all") then
	query = query
	..	"DROP TABLE IF EXISTS fsfax_settings;\n"
	end

	if (argv[2] == "config" or argv[2] == "all") then
	query = query
	..	"DROP TABLE IF EXISTS fsfax_config;\n"
	end

	if (argv[2] == "log" or argv[2] == "all") then
	query = query
	..	"DROP TABLE IF EXISTS fsfax_log;\n"
	end
	
	if (query ~= "") then	
		query = "BEGIN EXCLUSIVE TRANSACTION; \n"
		..	query
		..	"COMMIT TRANSACTION; \n"
		stream:write(query);
		dbh:query(query)
	end
	return;
end

if (argv[1] == "route") then
	if (argv[2] == "add") then

		if (argv[3] == nil or argv[4] == nil) then
			stream:write("fax route add [DID] [EMAIL]")
		else
			dbh:query("INSERT INTO fsfax_route (did,emailto) VALUES ('".. argv[3] .. "','".. argv[4] .."')")
		end
	

	elseif (argv[2] == "del") then
		if (argv[3] == nil) then
			stream:write("fax route del [DID]")
		else
			dbh:query("DELETE FROM fsfax_route where did='".. argv[3] .. "'")
		end


	elseif (argv[2] == "update") then

	elseif (argv[2] == "show") then
		dbh:query("SELECT * FROM fsfax_route", function(row)
			stream:write(string.format("%14s : %s\n", row.did, row.emailto))
		end)

	elseif (argv[2] == nil) then
		stream:write("fax route [add] [del] [update] [show]\n")
	else
		stream:write("fax unknown command.\n")
	end

	return;
end
