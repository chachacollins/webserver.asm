  section .data
  success_socket_create db ` Created a socket\n`
  success_socket_create_len equ $ -success_socket_create

  failure_socket_create db `could not create_socket\n`
  failure_socket_create_len equ $ - failure_socket_create 


  success_socket_bind db `successfully bind a socket\n`
  success_socket_bind_len equ $ -success_socket_bind

  failure_socket_bind db `Could not bind_socket\n`
  failure_socket_bind_len equ $ - failure_socket_bind


  success_listening db `successfully   listening to port 6969\n`
  success_listening_len equ $ - success_listening

  failure_listening db `Could not listen on port 6969\n`
  failure_listening_len equ $ - failure_listening


  success_accepting db `successfully   accepting to port 6969\n`
  success_accepting_len equ $ - success_accepting

  failure_accepting db `Could not accept  on port 6969\n`
  failure_accepting_len equ $ - failure_accepting

  failure_reading db `could not write to telnet\n`
  failure_reading_len equ $ - failure_reading

  hello_world_msg db "Hello, World!", 0x0A
  hello_world_len equ $ - hello_world_msg

  error_code_msg db "Accept error code: ", 0
  error_code_msg_len equ $ - error_code_msg
  newline db 0xA

  error_buffer db "    ", 0xA  
  error_buffer_len equ $ - error_buffer


  sys_close equ 0x03
  sys_write  equ  1
  sys_socket equ 0x29
  sys_bind equ 0x31
  sys_listen equ 0x32
  sys_accept equ 0x2b
  stdout     equ  1
  sys_exit equ 60
  AF_INET equ 2
  SOCK_STREAM equ 1
  PROTOCOL equ 0


  svraddr.sin_family dw 2
  svraddr.port dw 0x391b
  svraddr.ip_address dd 0
  svraddr.padding dq 0
  svraddr.size equ $ - svraddr.sin_family


  backlog equ 5

  section .bss
  socketfd resq 1
  clientfd resq 1
  error_code resq 1
clientaddr:
  resb 16   
clientaddrlen:
  resq 1  




  section .text
  global _start

_start:
  call create_socket
  call bind_socket
  call listen
  call accept
  call read_file
  call close
  mov rdi, 0
  call exit

print:
  mov rax, sys_write
  mov rdi, stdout
  syscall
  ret

exit:
  mov rax, sys_exit
  syscall

create_socket:
  mov rax, sys_socket 
  mov rdi, AF_INET    
  mov rsi, SOCK_STREAM 
  mov rdx, PROTOCOL    
  syscall         
  test rax, rax
  js error_socket_create
  mov [socketfd], rax
  mov rsi, success_socket_create
  mov rdx, success_socket_create_len
  call print
  ret

error_socket_create:
  mov rsi, failure_socket_create
  mov rdx, failure_socket_create_len
  call print

  mov rdi, 1
  call exit

bind_socket:
  mov rax, sys_bind
  mov rdi, [socketfd]
  lea rsi, [svraddr.sin_family]
  mov rdx, svraddr.size
  syscall

  test rax,rax
  js error_socket_bind
  mov rsi, success_socket_bind
  mov rdx, success_socket_bind_len
  call print
  ret


error_socket_bind:
  mov rsi, failure_socket_bind
  mov rdx, failure_socket_bind_len
  call print

  mov rdi, 1
  call exit

listen:
  mov rax, sys_listen
  mov rdi, [socketfd]
  mov rsi, backlog
  syscall
  test rax,rax
  js error_listen
  mov rsi, success_listening
  mov rdx, success_listening_len
  call print
  ret

error_listen:
  mov rsi, failure_listening
  mov rdx, failure_listening_len
  call print
  mov rdi, 1
  call exit

print_number:
  mov rcx, error_buffer
  add rcx, 3      
  mov byte [rcx], 0xA  
  mov rbx, 10    

  .loop:
  xor rdx, rdx  
  div rbx      
  add dl, '0' 
  dec rcx    
  mov [rcx], dl 
  test rax, rax
  jnz .loop

  mov rsi, rcx
  mov rdx, error_buffer
  add rdx, 4  
  sub rdx, rcx
  push rcx   
  call print
  pop rcx   
  ret

accept:
  mov qword [clientaddrlen], 16 

  mov rax, sys_accept
  mov rdi, [socketfd]
  mov rsi, clientaddr
  mov rdx, clientaddrlen 
  syscall

  test rax, rax
  js error_accepting

  mov [clientfd], rax    
  mov rsi, success_accepting
  mov rdx, success_accepting_len
  call print
  ret

error_accepting:
  mov rsi, failure_accepting
  mov rdx, failure_accepting_len
  call print

  mov rsi, error_code_msg
  mov rdx, error_code_msg_len
  call print

  mov rax, [error_code]
  neg rax    
  call print_number

  mov rdi, 1
  call exit


close:
  mov rax, sys_close
  mov rdi, [clientfd]
  syscall
  mov rax, sys_close
  mov rdi, [socketfd]
  syscall
  ret

read_file:
  mov rax, sys_write
  mov rdi, [clientfd]
  mov rsi, hello_world_msg
  mov rdx, hello_world_len 
  syscall
  test rax, rax
  js error_hello_world
  ret

error_hello_world:
  mov rsi, failure_reading
  mov rdx, failure_reading_len
  call print
  mov rdi, 1
  call exit
