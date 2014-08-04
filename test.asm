; Test program for the salsa20.asm library
; Compile with masm32 and step through e.g. OllyDbg to see the results ! (or add a message box)

.686
.model flat,stdcall 
option casemap:none 
include salsa20.inc
include salsa20.asm

.const
; 256bit key
k0 db 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
k1 db 201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216
; 16 bytes nonce (only the first 8 bytes are used, unless you use salsa20_setupivfull (don't))
n db 101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116
; Plaintext to encrypt
msg 	db "12345678123456781234567812345678123456781234567812345678123456781234567812345678"
msize db 80

.data
; Ciphertext (xor it with the plaintext and you get the hash, it should match the results in the spec)
cmsg 	db "00000000000000000000000000000000000000000000000000000000000000000000000000000000"

.data?
cryptoState salsa20_state <?>

.code
main proc
    invoke salsa20_setupkey32, offset cryptoState, offset k0
    invoke salsa20_setupiv, offset cryptoState, offset n
    invoke salsa20_encrypt, offset cryptoState, offset msg, offset cmsg, msize
main endp
end main
