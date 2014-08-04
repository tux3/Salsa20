; Internal state of the cipher
.code
salsa20_state struct
	input dword[16]	?
salsa20_state ends

; Constants for the expansion functions
.const
salsa20_sigma db "expand 32-byte k"
salsa20_tau db "expand 16-byte k"

; Prototypes
.code
salsa20_setupkey32 proto state:ptr, key:ptr
salsa20_setupkey16 proto state:ptr, key:ptr
salsa20_setupiv proto state:ptr, iv:ptr
salsa20_setupivfull proto state:ptr, iv:ptr
salsa20_encrypt proto state:ptr, msg:ptr, cmsg:ptr, msize:dword
salsa20_decrypt proto state:ptr, cmsg:ptr, msg:ptr, csize:dword
