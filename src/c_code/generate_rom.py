def rev_endian(text):
    return '\n'.join([text[i:i+4][::-1].hex() for i in range(0, len(text), 4)])

with open('ROM.bin', 'rb') as f:
    print(rev_endian(f.read()))