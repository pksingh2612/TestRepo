using centum_lms.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using System.Data;
using Newtonsoft.Json;
using System.IO;
using SelectPdf;
using Microsoft.AspNetCore.Http;
using System.Net.Mime;
using System.Text;
using ExcelDataReader;
using System.Linq;

namespace centum_lms.repository
{
    public class ChatBL : ControllerBase
    {
        public static bool isException = false;
        public static string exceptionMessage = "";
        public static DataSet ds;

        public async Task<IActionResult> GetLearnerAsync(string user_id)
        {
            Result res = new Result();
            try
            {
                Dictionary<string, object> param = new Dictionary<string, object>();
                param.Add("user_id", user_id);
                await Task.Run(() => DBLayer.UtilityDB.Ececute_Stored_Procedure("Proc_Chat", param, 101, ref isException, ref exceptionMessage, ref ds));
                if (!isException)
                {
                    return Ok(JsonConvert.SerializeObject(ds, Formatting.Indented));
                }
                else
                {
                    return StatusCode(400, exceptionMessage);
                }
            }
            catch (Exception ex)
            {
                res.message = ex.Message;
                return StatusCode(500, res.message);
            }
        }

        public async Task<IActionResult> PostMessageAsync(Models.ChatPL chatMessages)
        {
            Result res = new Result();
            try
            {
                var messageJson = JsonConvert.SerializeObject(chatMessages.messages, Formatting.Indented);
                Dictionary<string, object> param = new Dictionary<string, object>();
                param.Add("user_id", chatMessages.user_id);
                param.Add("message_json", messageJson);
                await Task.Run(() => DBLayer.UtilityDB.Ececute_Stored_Procedure("Proc_Chat", param, 102, ref isException, ref exceptionMessage, ref ds));
                if (!isException)
                {
                    return Ok(200);
                }
                else
                {
                    return StatusCode(400, exceptionMessage);
                }
            }
            catch (Exception ex)
            {
                res.message = ex.Message;
                return StatusCode(500, res.message);
            }
        }

        public List<ChatUser> MappedUserAsync(string user_id, string signalr_connectionId, bool chat_status)
        {
            Result res = new Result();
            try
            {
                Dictionary<string, object> param = new Dictionary<string, object>();
                param.Add("user_id", user_id);
                param.Add("signalr_connectionId", signalr_connectionId);
                param.Add("chat_status", chat_status);
                DBLayer.UtilityDB.Ececute_Stored_Procedure("Proc_Chat", param, 103, ref isException, ref exceptionMessage, ref ds);
                var myData = ds.Tables[0].AsEnumerable().Select(r => new ChatUser
                {
                    user_id = r.Field<string>("user_id"),
                    first_name = r.Field<string>("first_name"),
                    signalr_connectionId = r.Field<string>("signalr_connectionId"),
                    chat_status = r.Field<bool>("chat_status")
                });
                var list = myData.ToList();
                if (!isException)
                {
                    return list;
                }
                else
                {
                    return null;
                }
            }
            catch (Exception ex)
            {
                res.message = ex.Message;
                return null;
            }
        }

        public List<ChatUser> GetUserConnectionAsync()
        {
            Result res = new Result();
            try
            {
                Dictionary<string, object> param = new Dictionary<string, object>();
                DBLayer.UtilityDB.Ececute_Stored_Procedure("Proc_Chat", param, 104, ref isException, ref exceptionMessage, ref ds);
                var myData = ds.Tables[0].AsEnumerable().Select(r => new ChatUser
                {
                    user_id = r.Field<string>("user_id"),
                    first_name = r.Field<string>("first_name"),
                    signalr_connectionId = r.Field<string>("signalr_connectionId"),
                    chat_status = r.Field<bool>("chat_status")
                });
                var list = myData.ToList();
                if (!isException)
                {
                    return list;
                }
                else
                {
                    return null;
                }
            }
            catch (Exception ex)
            {
                res.message = ex.Message;
                return null;
            }
        }
    }
}