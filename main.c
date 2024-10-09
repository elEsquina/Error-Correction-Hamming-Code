#include <stdio.h>

typedef unsigned int uint;

void print_binary(uint number) {
    int bits = sizeof(number) * 8; 
    for (int i = bits - 1; i >= 0; i--) {
        uint mask = 1 << i;
        printf("%d", (number & mask) ? 1 : 0);
    }
    printf("\n");
}

uint parity(uint n){
    int count = 0;
    while (n)
    {
        n = n & (n - 1);
        count++;
    }
    return count%2;
}

uint get_message(uint matricule, uint r) {
    uint msg = matricule;
    msg ^= 0xFFFFFFFF; 
    msg = (msg << r) | (msg >> (32 - r));
    msg = msg & 0xFFFFFF;
    return msg;
}

uint hamming_map(uint matricule) {
    uint msg = matricule;
    printf("Message: 0x%X\n", msg);
    uint hamming = 0;
    int bit_position = 0;

    for (int i = 0; i < 32; i++) {
        if (i == 0 || ((i) & (i-1)) == 0) {
            hamming &= 0x7FFFFFFF;
        }
        else {
            if (msg & (1 << bit_position)){
                hamming |= (1 << 31);
            }
            bit_position++;
        }
        hamming >>= 1;
    }

    return hamming;
}

uint hamming_encode(uint map) {
    uint code = map;
    uint p;
    p = parity( map & 0x55555554 );
    code |= p;
    p = parity( map & 0x66666664 );
    code |= (p << 1);
    p = parity( map & 0x78787870 );
    code |= (p << 3);
    p = parity( map & 0x7F807F00 );
    code |= (p << 7);
    p = parity( map & 0x7FFF0000 );
    code |= (p << 15);
    return code;
}

uint haming_decode(uint code){
    uint c0 = parity( code & 0x55555555 );
    uint c1 = parity( code & 0x66666666 );
    uint c2 = parity( code & 0x78787878 );
    uint c3 = parity( code & 0x7F807F80 );
    uint c4 = parity( code & 0x7FFF8000 );
    uint C = c0 | c1<<1 | c2<<2 | c3<<3 | c4<<4; 
    if (C != 0){
        printf("Error at position: %d\n", C-1);
        code ^= (1 << (C - 1));
    }
    return code;
}

uint haming_unmap(uint map){
    uint hamming = map;
    uint matricule = 0;
    uint bit_position = 0;
    for (int i = 0; i < 32; i++) {
        if ((i+1 & i) == 0) {
            continue;
        }
        else {
            if (hamming & (1 << i)) {
                matricule |= (1 << bit_position);
            }
            bit_position++;
        }
    }
    printf("Message: 0x%X\n", matricule);

    return matricule;
}

int main() {
    uint matricule = 0x124B7F; 
    uint r = 8; 

    printf("Matricule: 0x%X\n", matricule);
    uint msg = get_message(matricule, r);

    return 0;
}
