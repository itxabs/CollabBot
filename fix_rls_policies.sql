-- Fix RLS policies for messages table to allow chat participants to delete messages
-- This enables the receiver to delete messages from Supabase after storing locally

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view messages in their chats" ON messages;
DROP POLICY IF EXISTS "Users can insert messages in their chats" ON messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;

-- Allow users to view messages in chats they participate in
CREATE POLICY "Users can view messages in their chats" ON messages
FOR SELECT USING (
  auth.uid() IN (
    SELECT user_id FROM chat_participants WHERE chat_id = messages.chat_id
  )
);

-- Allow users to insert messages in chats they participate in
CREATE POLICY "Users can insert messages in their chats" ON messages
FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND
  auth.uid() IN (
    SELECT user_id FROM chat_participants WHERE chat_id = messages.chat_id
  )
);

-- Allow users to delete messages in chats they participate in (for receiver cleanup)
CREATE POLICY "Users can delete messages in their chats" ON messages
FOR DELETE USING (
  auth.uid() IN (
    SELECT user_id FROM chat_participants WHERE chat_id = messages.chat_id
  )
);

-- Same for message_attachments
DROP POLICY IF EXISTS "Users can view attachments in their chats" ON message_attachments;
DROP POLICY IF EXISTS "Users can insert attachments in their chats" ON message_attachments;
DROP POLICY IF EXISTS "Users can delete attachments in their chats" ON message_attachments;

CREATE POLICY "Users can view attachments in their chats" ON message_attachments
FOR SELECT USING (
  auth.uid() IN (
    SELECT cp.user_id FROM chat_participants cp
    JOIN messages m ON m.id = message_attachments.message_id
    WHERE cp.chat_id = m.chat_id
  )
);

CREATE POLICY "Users can insert attachments in their chats" ON message_attachments
FOR INSERT WITH CHECK (
  auth.uid() IN (
    SELECT cp.user_id FROM chat_participants cp
    JOIN messages m ON m.id = message_attachments.message_id
    WHERE cp.chat_id = m.chat_id
  )
);

CREATE POLICY "Users can delete attachments in their chats" ON message_attachments
FOR DELETE USING (
  auth.uid() IN (
    SELECT cp.user_id FROM chat_participants cp
    JOIN messages m ON m.id = message_attachments.message_id
    WHERE cp.chat_id = m.chat_id
  )
);