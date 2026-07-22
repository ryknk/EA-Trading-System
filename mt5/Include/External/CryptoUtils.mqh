#ifndef EA_TRADING_SYSTEM_CRYPTO_UTILS_MQH
#define EA_TRADING_SYSTEM_CRYPTO_UTILS_MQH

class CCryptoUtils
  {
public:
   static bool Utf8Bytes(const string value,uchar &bytes[])
     {
      ArrayResize(bytes,0);
      const int count=StringToCharArray(value,bytes,0,WHOLE_ARRAY,CP_UTF8);
      if(count<=0) return StringLen(value)==0;
      if(ArraySize(bytes)>0 && bytes[ArraySize(bytes)-1]==0)
         ArrayResize(bytes,ArraySize(bytes)-1);
      return true;
     }

   static bool Sha256Bytes(const uchar &data[],uchar &digest[])
     {
      uchar key[];
      ArrayResize(key,0);
      ArrayResize(digest,0);
      ResetLastError();
      return CryptEncode(CRYPT_HASH_SHA256,data,key,digest)==32;
     }

   static bool Sha256Hex(const string value,string &hex)
     {
      uchar data[],digest[];
      hex="";
      if(!Utf8Bytes(value,data) || !Sha256Bytes(data,digest)) return false;
      hex=BytesToHex(digest);
      return StringLen(hex)==64;
     }

   static bool HmacSha256Hex(const string secret,const string message,string &hex)
     {
      hex="";
      uchar key[],message_bytes[];
      if(!Utf8Bytes(secret,key) || !Utf8Bytes(message,message_bytes) || ArraySize(key)==0)
         return false;
      if(ArraySize(key)>64)
        {
         uchar hashed_key[];
         if(!Sha256Bytes(key,hashed_key)) return false;
         ArrayCopy(key,hashed_key);
        }

      uchar inner_pad[],outer_pad[];
      ArrayResize(inner_pad,64);
      ArrayResize(outer_pad,64);
      for(int index=0; index<64; index++)
        {
         const uchar key_byte=(index<ArraySize(key) ? key[index] : 0);
         inner_pad[index]=(uchar)(key_byte^0x36);
         outer_pad[index]=(uchar)(key_byte^0x5c);
        }

      uchar inner_data[];
      ArrayResize(inner_data,64+ArraySize(message_bytes));
      ArrayCopy(inner_data,inner_pad,0,0,64);
      if(ArraySize(message_bytes)>0)
         ArrayCopy(inner_data,message_bytes,64,0,ArraySize(message_bytes));
      uchar inner_hash[];
      if(!Sha256Bytes(inner_data,inner_hash)) return false;

      uchar outer_data[];
      ArrayResize(outer_data,64+ArraySize(inner_hash));
      ArrayCopy(outer_data,outer_pad,0,0,64);
      ArrayCopy(outer_data,inner_hash,64,0,ArraySize(inner_hash));
      uchar outer_hash[];
      if(!Sha256Bytes(outer_data,outer_hash)) return false;
      hex=BytesToHex(outer_hash);
      return StringLen(hex)==64;
     }

   static string BytesToHex(const uchar &bytes[])
     {
      string result="";
      for(int index=0; index<ArraySize(bytes); index++)
         result+=StringFormat("%02x",bytes[index]);
      return result;
     }

   static string JsonEscape(const string value)
     {
      string result="";
      for(int index=0; index<StringLen(value); index++)
        {
         const ushort character=StringGetCharacter(value,index);
         if(character=='"') result+="\\\"";
         else if(character=='\\') result+="\\\\";
         else if(character==8) result+="\\b";
         else if(character==9) result+="\\t";
         else if(character==10) result+="\\n";
         else if(character==12) result+="\\f";
         else if(character==13) result+="\\r";
         else if(character<32) result+=StringFormat("\\u%04x",character);
         else result+=ShortToString(character);
        }
      return result;
     }

   static bool GenerateUuid(string &uuid)
     {
      const string entropy=StringFormat("%I64u|%I64d|%I64u|%d|%d",
                                        GetMicrosecondCount(),(long)TimeLocal(),
                                        (ulong)AccountInfoInteger(ACCOUNT_LOGIN),MathRand(),GetTickCount());
      string hash;
      if(!Sha256Hex(entropy,hash)) return false;
      // RFC 4122 textual shape. Randomness is local entropy; HMAC supplies request authenticity.
      uuid=StringSubstr(hash,0,8)+"-"+StringSubstr(hash,8,4)+"-4"+StringSubstr(hash,13,3)+
           "-a"+StringSubstr(hash,17,3)+"-"+StringSubstr(hash,20,12);
      return StringLen(uuid)==36;
     }
  };

#endif
