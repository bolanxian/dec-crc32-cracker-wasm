
#define WASM_EXPORT __attribute__((visibility("default")))
#define u32 unsigned int
#define i32 int
#define u8 unsigned char
#define i8 char
u32 table[256];
WASM_EXPORT void *init(u32 POLY)
{
  for (u32 i = 0u; i < 256u; i++)
  {
    u32 j = i;
    for (u8 _ = 0u; _ < 8u; _++)
    {
      j = j & 1u ? j >> 1u ^ POLY : j >> 1u;
    }
    table[i] = j;
  }
  return table;
}
u8 crc_index;
u32 crc32(u8 *str, u8 len)
{
  u32 crc = ~0u;
  for (u8 i = 0u; i < len; i++)
  {
    crc_index = (crc ^ str[i]) & 0xFFu;
    crc = crc >> 8u ^ table[crc_index];
  }
  return crc;
}
u8 lastIndex(u8 crc)
{
  for (u32 i = 0u; i < 256u; i++)
  {
    if (crc == table[i] >> 24u)
    {
      return i;
    }
  }
  return 0u;
}
union
{
  u32 value;
  u8 bytes[4];
} indexes;
WASM_EXPORT u32 getIndexes(u32 crc)
{
  for (u8 i = 3u, j = 0u; j < 4u; i--, j++)
  {
    u8 crc_index = indexes.bytes[j] = lastIndex(crc >> (i << 3u));
    u32 value = table[crc_index];
    crc ^= value >> (j << 3u);
  }
  return indexes.value;
}
u8 itoa(u32 unum, u8 *str)
{
  u8 i = 0u;
  do
  {
    str[i++] = unum % 10u + 48u;
    unum /= 10u;
  } while (unum);
  for (u8 j = 0u; j <= (i - 1u) / 2u; j++)
  {
    u8 temp = str[j];
    str[j] = str[i - 1u - j];
    str[i - 1u - j] = temp;
  }
  return i;
}
u8 str[10];
WASM_EXPORT u32 crc32_dec(u32 i)
{
  u8 len = itoa(i, str);
  u32 crc = crc32(str, len);
  return crc;
}
u32 check(u32 i)
{
  u8 len = itoa(i, str);
  u32 crc = crc32(str, len);
  if (crc_index != indexes.bytes[3])
  {
    return -1;
  }
  u32 low = 0u;
  for (i8 i = 2; i > -1; i--)
  {
    u8 num = (crc & 0xFFu) ^ indexes.bytes[i];
    if (num < 48u || num > 57u)
    {
      return -1;
    }
    low = low << 4u | (num - 48u);
    crc = crc >> 8u ^ table[indexes.bytes[i]];
  }
  return low;
}
WASM_EXPORT u32 checkIndex(u32 i, u32 indexes_value)
{
  indexes.value = indexes_value;
  return check(i);
}
WASM_EXPORT i32 findIndex(u32 indexes_value, i32 begin, i32 end)
{
  indexes.value = indexes_value;
  for (i32 i = begin; i < end; i++)
  {
    i32 low = check(i);
    if (low >= 0)
    {
      return i;
    }
  }
  return -1;
}