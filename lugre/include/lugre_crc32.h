#pragma once

#include <cstdint>

namespace Lugre
{


class CRC32
{
    // Code originally from https://rosettacode.org/wiki/CRC-32 released under the GNU Free Documentation License, Version 1.2

public:

    CRC32()
    {
        // Initialize the CRC table.
        for (int i = 0; i < 256; i++)
        {
            uint32_t remainder = i;
            for (int j = 0; j < 8; j++)
            {
                if (remainder & 1)
                {
                    remainder >>= 1;
                    remainder ^= 0xedb88320;
                }
                else
                    remainder >>= 1;
            }
            _table[i] = remainder;
        }
    }
    
    void ProcessBytes(const char* buf, size_t len)
    {
        if (!buf || !len)
        {
            return;
        }

        _crc = ~_crc;
        const char* q = buf + len;
        for (const char* p = buf; p < q; p++)
        {
            uint8_t octet = *p;  // Cast to unsigned octet.
            _crc = (_crc >> 8) ^ _table[(_crc & 0xff) ^ octet];
        }
    }

    uint32_t Checksum() const
    {
        return ~_crc;
    }

private:

    uint32_t _table[256];
    uint32_t _crc{ 0 };

};

} 