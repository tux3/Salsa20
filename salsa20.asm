.code

; This macro performs the quarterround function
; It assumes that eax, ebx, ecx, edx are the 4 input dwords y0,y1,y2,y3
; This macro modifies esi
; The results z0,z1,z2,z3 are stored in-place in y0,y1,y2,y3
salsa20_QuarterRound macro
	; z1
	mov esi, eax
	add esi, edx
	rol esi, 7
	xor ebx, esi
	
	; z2
	mov esi, ebx
	add esi, eax 
	rol esi, 9
	xor ecx, esi
	
	; z3
	mov esi, ecx
	add esi, ebx
	rol esi, 13
	xor edx, esi
	
	; z0
	mov esi, edx
	add esi, ecx
	rol esi, 18
	xor eax, esi
endm



; This macro performs the rowround function
; It assumes that edi points to the start of an array of 16 input dwords
; This macro modifies eax, ebx, ecx, edx, esi
; The results are stored in-place
salsa20_RowRound macro
	; z0, z1, z2, z3
	mov eax, [edi+4*0]
	mov ebx, [edi+4*1]
	mov ecx, [edi+4*2]
	mov edx, [edi+4*3]
	salsa20_QuarterRound
	mov [edi+4*0], eax
	mov [edi+4*1], ebx
	mov [edi+4*2], ecx
	mov [edi+4*3], edx
	
	; z5, z6, z7, z4
	mov eax, [edi+4*5]
	mov ebx, [edi+4*6]
	mov ecx, [edi+4*7]
	mov edx, [edi+4*4]
	salsa20_QuarterRound
	mov [edi+4*5], eax
	mov [edi+4*6], ebx
	mov [edi+4*7], ecx
	mov [edi+4*4], edx
	
	; z10, z11, z8, z9
	mov eax, [edi+4*10]
	mov ebx, [edi+4*11]
	mov ecx, [edi+4*8]
	mov edx, [edi+4*9]
	salsa20_QuarterRound
	mov [edi+4*10], eax
	mov [edi+4*11], ebx
	mov [edi+4*8], ecx
	mov [edi+4*9], edx
	
	; z15, z12, z13, z14
	mov eax, [edi+4*15]
	mov ebx, [edi+4*12]
	mov ecx, [edi+4*13]
	mov edx, [edi+4*14]
	salsa20_QuarterRound
	mov [edi+4*15], eax
	mov [edi+4*12], ebx
	mov [edi+4*13], ecx
	mov [edi+4*14], edx
endm



; This macro performs the columnround function
; It assumes that edi points to the start of an array of 16 input dwords
; This macro modifies eax, ebx, ecx, edx, esi
; The results are stored in-place
salsa20_ColumnRound macro
	; z0, z4, z8, z12
	mov eax, [edi+4*0]
	mov ebx, [edi+4*4]
	mov ecx, [edi+4*8]
	mov edx, [edi+4*12]
	salsa20_QuarterRound
	mov [edi+4*0], eax
	mov [edi+4*4], ebx
	mov [edi+4*8], ecx
	mov [edi+4*12], edx
	
	; z5, z9, z13, z1
	mov eax, [edi+4*5]
	mov ebx, [edi+4*9]
	mov ecx, [edi+4*13]
	mov edx, [edi+4*1]
	salsa20_QuarterRound
	mov [edi+4*5], eax
	mov [edi+4*9], ebx
	mov [edi+4*13], ecx
	mov [edi+4*1], edx
	
	; z10, z14, z2, z6
	mov eax, [edi+4*10]
	mov ebx, [edi+4*14]
	mov ecx, [edi+4*2]
	mov edx, [edi+4*6]
	salsa20_QuarterRound
	mov [edi+4*10], eax
	mov [edi+4*14], ebx
	mov [edi+4*2], ecx
	mov [edi+4*6], edx
	
	; z15, z3, z7, z11
	mov eax, [edi+4*15]
	mov ebx, [edi+4*3]
	mov ecx, [edi+4*7]
	mov edx, [edi+4*11]
	salsa20_QuarterRound
	mov [edi+4*15], eax
	mov [edi+4*3], ebx
	mov [edi+4*7], ecx
	mov [edi+4*11], edx
endm



; This macro performs the doubleround function
; It assumes that edi points to the start of an array of 16 input dwords
; This macro modifies eax, ebx, ecx, edx, esi
; The results are stored in-place
salsa20_DoubleRound macro
	salsa20_ColumnRound
	salsa20_RowRound
endm



; This macro performs the salsa20 hash function
; It assumes that esi points to the start of an array of 16 input dwords,
; that edi points to the start of an array of 16 output dwords and that the output
; dwords are initially a copy of the input dwords
; This macro modifies eax, ebx, ecx, edx and uses the stack
; The results are stored in-place, the input dwords are not modified
salsa20_hash macro
	push ebp
	
	;; Run the double rounds on the output (the copy of inputs)
	push esi
	mov ebp, 10
@@: salsa20_DoubleRound
	dec ebp
	jnz @B
	pop esi
	
	;; Add back inputs to outputs
	mov ecx, 15
@@: mov edx, [esi+4*ecx]
	add [edi+4*ecx], edx
	dec ecx
	jge @B
	
	pop ebp
endm



; This function performs a salsa20 expansion of a 32-byte key (256 bits)
; Assumes that k points to a 32-byte key, and n points to a 16-byte nounce
; Assumes that esi points to the destination buffer
; This function modifies edi and uses the stack
salsa20_expand32 macro k:req, n:req
	mov edi, offset salsa20_sigma
	
	mov [esi+4*0], [edi+4*0]
	mov [esi+4*5], [edi+4*1]
	mov [esi+4*10], [edi+4*2]
	mov [esi+4*15], [edi+4*3]
	mov edi, k
	mov [esi+4*1], [edi+4*0]
	mov [esi+4*2], [edi+4*1]
	mov [esi+4*3], [edi+4*2]
	mov [esi+4*4], [edi+4*3]
	mov [esi+4*11], [edi+4*4]
	mov [esi+4*12], [edi+4*5]
	mov [esi+4*13], [edi+4*6]
	mov [esi+4*14], [edi+4*7]
	mov edi, n
	mov [esi+4*6], [edi+4*0]
	mov [esi+4*7], [edi+4*1]
	mov [esi+4*8], [edi+4*2]
	mov [esi+4*9], [edi+4*3]
	
	mov edi, esi
	salsa20_hash
endm



; This function performs a salsa20 expansion of a 16-byte key (256 bits)
; Assumes that k points to a 16-byte key, and n points to a 16-byte nounce
; Assumes that esi points to the destination buffer
; This function modifies edi and uses the stack
salsa20_expand16 macro k:req, n:req
	add esp, 64
	mov edi, offset salsa20_tau
	
	mov [esi+4*0], [edi+4*0]
	mov [esi+4*5], [edi+4*1]
	mov [esi+4*10], [edi+4*2]
	mov [esi+4*15], [edi+4*3]
	mov edi, k
	mov [esi+4*1], [edi+4*0]
	mov [esi+4*2], [edi+4*1]
	mov [esi+4*3], [edi+4*2]
	mov [esi+4*4], [edi+4*3]
	mov [esi+4*11], [edi+4*0]
	mov [esi+4*12], [edi+4*1]
	mov [esi+4*13], [edi+4*2]
	mov [esi+4*14], [edi+4*3]
	mov edi, n
	mov [esi+4*6], [edi+4*0]
	mov [esi+4*7], [edi+4*1]
	mov [esi+4*8], [edi+4*2]
	mov [esi+4*9], [edi+4*3]
	
	mov edi, esi
	salsa20_hash
endm



; Prepare the cipher's internal state to use the given key
; The key must have a size of 256 bits
; Returns nothing
salsa20_setupkey32 proc state:ptr, key:ptr
	mov eax, state
	
	mov ecx, offset salsa20_sigma
	mov edx, [ecx+4*0]
	mov [eax+4*0], edx
	mov edx, [ecx+4*1]
	mov [eax+4*5], edx
	mov edx, [ecx+4*2]
	mov [eax+4*10], edx
	mov edx, [ecx+4*3]
	mov [eax+4*15], edx
	
	mov ecx, key
	mov edx, [ecx+4*0]
	mov [eax+4*1], edx
	mov edx, [ecx+4*1]
	mov [eax+4*2], edx
	mov edx, [ecx+4*2]
	mov [eax+4*3], edx
	mov edx, [ecx+4*3]
	mov [eax+4*4], edx
	mov edx, [ecx+4*4]
	mov [eax+4*11], edx
	mov edx, [ecx+4*5]
	mov [eax+4*12], edx
	mov edx, [ecx+4*6]
	mov [eax+4*13], edx
	mov edx, [ecx+4*7]
	mov [eax+4*14], edx
	ret
salsa20_setupkey32 endp



; Prepare the cipher's internal state to use the given key
; The key must have a size of 128 bits
; Returns nothing
salsa20_setupkey16 proc state:ptr, key:ptr
	mov eax, state
	
	mov ecx, offset salsa20_tau
	mov edx, [ecx+4*0]
	mov [eax+4*0], edx
	mov edx, [ecx+4*1]
	mov [eax+4*5], edx
	mov edx, [ecx+4*2]
	mov [eax+4*10], edx
	mov edx, [ecx+4*3]
	mov [eax+4*15], edx
	
	mov ecx, key
	mov edx, [ecx+4*0]
	mov [eax+4*1], edx
	mov edx, [ecx+4*1]
	mov [eax+4*2], edx
	mov edx, [ecx+4*2]
	mov [eax+4*3], edx
	mov edx, [ecx+4*3]
	mov [eax+4*4], edx
	mov edx, [ecx+4*0]
	mov [eax+4*11], edx
	mov edx, [ecx+4*1]
	mov [eax+4*12], edx
	mov edx, [ecx+4*2]
	mov [eax+4*13], edx
	mov edx, [ecx+4*3]
	mov [eax+4*14], edx
	ret
salsa20_setupkey16 endp



; Prepare the cipher's internal state to use the given IV
; The iv must have a size of at least 32 bits
; Returns nothing
salsa20_setupiv proc state:ptr, iv:ptr
	mov eax, state
	mov edx, iv
	mov ecx, [edx+4*0]
	mov [eax+4*6], ecx
	mov ecx, [edx+4*1]
	mov [eax+4*7], ecx
	xor ecx,ecx
	mov [eax+4*8], ecx
	mov [eax+4*9], ecx
	ret
salsa20_setupiv endp



; Prepare the cipher's internal state to use the given IV fully
; The iv must have a size of 64 bits
; Returns nothing
salsa20_setupivfull proc state:ptr, iv:ptr
	mov eax, state
	mov edx, iv
	mov ecx, [edx+4*0]
	mov [eax+4*6], ecx
	mov ecx, [edx+4*1]
	mov [eax+4*7], ecx
	mov ecx, [edx+4*2]
	mov [eax+4*8], ecx
	mov ecx, [edx+4*3]
	mov [eax+4*9], ecx
	ret
salsa20_setupivfull endp



; Encrypts the plaintext m with the given internal state
; This function assumes that the state is valid, use setupkey and setupiv first
; Outputs the cyphertext to c
; Returns nothing
salsa20_encrypt proc state:ptr, msg:ptr, cmsg:ptr, msize:dword
	local j[16]:dword, x[16]:dword, tmp[64]:byte, ctarget:ptr
	mov eax, msize
	test eax, eax
	jz done
	push esi
	push edi
	push ebx
	
	; Prepare j
	mov eax, state
	lea ebx, j
	mov ecx, 15
@@: mov edx, [eax+4*ecx]
	mov [ebx+4*ecx], edx
	dec ecx
	jge @B
	
	; Main loop
mainLoop:
	; Use our tmp buffer if less than 64B is left
	.if msize < 64
		mov ebx, msg
		mov ecx, msize
		dec ecx
		lea edx, tmp
	@@:	mov al, byte ptr [ebx+ecx]
		mov [edx+ecx], al
		dec ecx
		jge @B
		mov msg, edx
		mov eax, cmsg
		mov ctarget, eax
		mov cmsg, edx
	.endif
	
	; Prepare x
	lea eax, j
	lea ebx, x
	mov ecx, 15
@@: mov edx, [eax+4*ecx]
	mov [ebx+4*ecx], edx
	dec ecx
	jge @B
	
	; Compute hash & xor
	lea esi, j
	lea edi, x
	salsa20_hash
	mov eax, msg
	mov ecx, 15
@@: mov edx, [eax+4*ecx]
	xor [edi+4*ecx], edx
	dec ecx
	jge @B
	
	; Increment the nonce
	inc [j+4*8]
	.if [j+4*8] == 0
		inc [j+4*9]
	.endif
	
	; Write the ciphertext
	lea eax, x
	mov ebx, cmsg
	mov ecx, 15
@@: mov edx, [eax+4*ecx]
	mov [ebx+4*ecx], edx
	dec ecx
	jge @B
	
	; The last block is handled differently
	mov eax, msize
	.if eax <= 64
		.if eax < 64
			; We're using the tmp buffer, need to copy to ctarget
			mov eax, cmsg
			mov ebx, ctarget
			mov ecx, msize
			dec ecx
		@@: mov dl, [eax+ecx]
			mov [ebx+ecx], dl
			dec ecx
			jge @B
		.endif
		mov edx, state
		mov eax, [j+4*8]
		mov [edx+4*8], eax
		mov eax, [j+4*9]
		mov [edx+4*9], eax
		jmp cleanup
	.endif
	
	sub msize, 64
	add cmsg, 64
	add msg, 64
	jmp mainLoop
	
cleanup:
	pop ebx
	pop edi
	pop esi
done:
	ret
salsa20_encrypt endp



; Decrypts the cyphertext c with the given internal state
; Outputs the plaintext to m
; Returns nothing
salsa20_decrypt proc state:ptr, cmsg:ptr, msg:ptr, csize:dword
	invoke salsa20_encrypt, state, cmsg, msg, csize
	ret
salsa20_decrypt endp
