USE [centum_lms_dev7]
GO

/****** Object: SqlProcedure [dbo].[Proc_Chat] Script Date: 8/31/2022 9:09:16 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--exec Proc_Chat @OpCode=101,@isException=0,@exceptionMessage=''
ALTER PROCEDURE [dbo].[Proc_Chat]
	@OpCode [INT],
	@signalr_connectionId [NVARCHAR](200) = NULL,
	@chat_status [BIT] = NULL,
	@user_id [NVARCHAR](20) = NULL,
	@message_json [NVARCHAR](MAX) = NULL,
	@order_json [NVARCHAR](MAX) = NULL,
	@unReadMsgCount int = NULL,
	@unReadMsg_json [NVARCHAR](MAX) = NULL,
	@isException [BIT] OUTPUT,
	@exceptionMessage [NVARCHAR](500) OUTPUT
WITH EXECUTE AS CALLER
AS
BEGIN                                                
 BEGIN TRY                                
 SET @isException=0                                
                                    
 IF @OpCode=101  --Get Learner List 
 BEGIN
	DECLARE @chat_template NVARCHAR(MAX) = '{"messages":"","order": "","unReadMsg":""}'
	DECLARE @chat_data NVARCHAR(MAX)='[]'
	DECLARE @order_data NVARCHAR(MAX)='[]'
	DECLARE @unread_data NVARCHAR(MAX)='[]'
	IF EXISTS(SELECT 1 FROM tbl_CHAT_content_details WHERE userId=@user_id)
	BEGIN
		SELECT @order_data = ISNULL(userSequence, '[]'), @unread_data= ISNULL(unReadMsg,'[]') FROM tbl_CHAT_content_setting WHERE userId=@user_id
		SET @chat_data = (SELECT contents AS content,fromSelf,chatDateTime AS [time], full_datetime AS [fullTime],reciever AS [to],sender AS [from] 
						FROM tbl_CHAT_content_details WHERE userId=@user_id FOR JSON AUTO)
	END

	SET @chat_template = JSON_MODIFY(@chat_template,'$.messages',JSON_QUERY(@chat_data))
	SET @chat_template = JSON_MODIFY(@chat_template,'$.order',JSON_QUERY(@order_data))
	SET @chat_template = JSON_MODIFY(@chat_template,'$.unReadMsg',JSON_QUERY(@unread_data))

	SELECT @chat_template AS chat_details


	--SELECT u.user_id,u.first_name,u.last_name,u.photograph_url,u.logged_in 
	--	FROM tbl_UMN_MST_user u join tbl_UMN_MST_user_role r on u.[user_id] = r.[user_id] and r.role_id='ROL0000004'
 END
 IF @OpCode=102  --Post Message 
 BEGIN
	BEGIN TRANSACTION
		INSERT INTO tbl_CHAT_content_details(userId,contents,fromSelf,chatDateTime,full_datetime,reciever,sender)
		SELECT @user_id,content,fromSelf,[time],[fullTime],[to],[from] FROM  
		OPENJSON (@message_json)  
		WITH (   
				content		NVARCHAR(MAX)	'$.content',
				fromSelf	BIT				'$.fromSelf',
				[from]      NVARCHAR(20)	'$.from',  
				[time]      NVARCHAR(50)	'$.time',  
				[fullTime]  DATETIME		'$.fullTime',  
				[to]        NVARCHAR(20)	'$.to'  
		 )

		IF EXISTS(SELECT 1 FROM tbl_CHAT_content_setting WHERE userId=@user_id)
		BEGIN
			UPDATE tbl_CHAT_content_setting
				SET userSequence=@order_json,
					unReadMsg=@unReadMsg_json
				WHERE userId=@user_id 
		END
		ELSE
			BEGIN
				INSERT INTO tbl_CHAT_content_setting(userId,userSequence,unReadMsg)
				SELECT @user_id,@order_json,@unReadMsg_json
			END
	COMMIT TRANSACTION
 END
 IF @OpCode=103  --Mapping SignalR Connection Id with userId 
 BEGIN
	--UPDATE tbl_UMN_MST_user
	--	SET signalr_connectionId = @signalr_connectionId,
	--	chat_status = @chat_status
	--WHERE user_id = @user_id
	INSERT INTO tbl_CHAT_users(userId,signalr_connectionId,[status])
	SELECT @user_id,@signalr_connectionId,@chat_status

	SELECT u.user_id,u.first_name,u.last_name,u.photograph_url,u.logged_in,
		ISNULL(signalr_connectionId,'') AS signalr_connectionId,ISNULL(chat_status,0) AS chat_status
		FROM tbl_UMN_MST_user u join tbl_CHAT_users c on u.[user_id] = c.[user_id] 
		WHERE u.user_id in('USR0000027','USR0000028','USR0000029')

	--SELECT u.user_id,u.first_name,u.last_name,u.photograph_url,u.logged_in,
	--	ISNULL(signalr_connectionId,'') AS signalr_connectionId,ISNULL(chat_status,0) AS chat_status
	--	FROM tbl_UMN_MST_user u join tbl_UMN_MST_user_role r on u.[user_id] = r.[user_id] and r.role_id='ROL0000004'
	--	WHERE u.user_id in('USR0000027','USR0000028','USR0000029')
 END
 IF @OpCode=104  --Get users with SignalR Connection Id
 BEGIN
	SELECT u.user_id,u.first_name,u.last_name,u.photograph_url,u.logged_in,
		ISNULL(signalr_connectionId,'') AS signalr_connectionId,ISNULL(chat_status,0) AS chat_status
		FROM tbl_UMN_MST_user u join tbl_UMN_MST_user_role r on u.[user_id] = r.[user_id] and r.role_id='ROL0000004'
		WHERE u.user_id in('USR0000027','USR0000028','USR0000029')
 END
 END 
 TRY                        
 BEGIN CATCH                                            
 if @@trancount>0 ROLLBACK TRANSACTION                                            
 SET @isException=1                                                
 SET @exceptionMessage=error_message()                                                                                                                
 END CATCH;                                                
END
