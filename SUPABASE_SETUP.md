## 🔑 Supabase API Key Setup

Your app is trying to connect to Supabase but needs the correct API key.

### How to get your Supabase API Key:

1. **Go to Supabase Dashboard**: https://supabase.com/dashboard
2. **Select your project**: `qctrtvzuazdvuwhwyops`
3. **Go to Settings > API**
4. **Copy the "anon public" key**

### Current Connection Details:
- **URL**: `https://qctrtvzuazdvuwhwyops.supabase.co`
- **Database**: `postgresql://postgres:smartattendence@db.qctrtvzuazdvuwhwyops.supabase.co:5432/postgres`
- **Status**: ❌ API key needed

### Error Message:
```
Database connection test failed: 401
Response: {"message":"Invalid API key","hint":"Double check your Supabase `anon` or `service_role` API key."}
```

### Next Steps:
1. **Get your API key** from Supabase Dashboard
2. **Update the service** with your real API key
3. **Create database tables** (if they don't exist)
4. **Test the connection**

### Database Tables Needed:
- `schools` - Store school information
- `staff` - Store staff/teacher accounts  
- `students` - Store student information

The app structure is ready - we just need your API key to connect! 🚀