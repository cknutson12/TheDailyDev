-- Create a database function to get user_id by email from auth.users
-- This function can be called from Edge Functions using RPC
-- The service role has access to auth.users, so this function will work

CREATE OR REPLACE FUNCTION get_user_id_by_email(user_email TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id UUID;
BEGIN
  -- Query auth.users table (service role has access)
  SELECT id INTO user_id
  FROM auth.users
  WHERE email = LOWER(user_email)
  LIMIT 1;
  
  RETURN user_id;
END;
$$;

-- Grant execute permission to authenticated users (Edge Functions use service role)
GRANT EXECUTE ON FUNCTION get_user_id_by_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_id_by_email(TEXT) TO service_role;

COMMENT ON FUNCTION get_user_id_by_email(TEXT) IS 'Returns user_id from auth.users by email. Used by webhook to link Stripe customers to users.';

