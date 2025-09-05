-- Create ai_suggestions table
CREATE TABLE ai_suggestions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    conversation_text TEXT NOT NULL,
    suggestion_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Add RLS (Row Level Security) policies
ALTER TABLE ai_suggestions ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read only their own suggestions
CREATE POLICY "Users can view their own suggestions"
ON ai_suggestions
FOR SELECT
USING (auth.uid() = user_id);

-- Create policy to allow the service role to insert suggestions
CREATE POLICY "Service role can insert suggestions"
ON ai_suggestions
FOR INSERT
WITH CHECK (true);  -- Since this will be done by the backend service

-- Create index for faster queries
CREATE INDEX ai_suggestions_user_id_idx ON ai_suggestions(user_id);
CREATE INDEX ai_suggestions_created_at_idx ON ai_suggestions(created_at);
