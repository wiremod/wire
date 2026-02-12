local Test = {}


-- This is a real ZCPU program that sets itself up as a BIOS for a paged memory system
-- It's currently the most complex program that doesn't require emulating hardware that
-- I have available for benchmarking purposes.
Test.Files = {
	["palloc.txt"] = [[
DATA

smint:
ALLOC 20*4
DB psoftware_interrupt_handler,0,os_ptable,160
smint_end:

// This needs to set up a stack, so these are the registers required
// to be stored beforehand so as to not destroy anything the user might want.
psoftware_eax:
DB 0
psoftware_esi:
DB 0
psoftware_ds:
DB 0
psoftware_interrupt_handler:
	// EAX = interrupt to call, saved.
	// Args vary based on interrupt after that point.
CLI
	MOV [CS:psoftware_ds],DS // CS is the only register we can trust to be zeroed right now without destroying it first.
	MOV DS,0
	MOV [psoftware_eax],EAX
	MOV [psoftware_esi],ESI // Because we don't want to destroy DS nor do we want to use it.
	XCHG EAX,EDX
	CPUGET EDX,41
	MOV [pmem_find_requester_stackless_return],psoftware_got_requester
	JMP pmem_find_requester_stackless
	psoftware_got_requester:
	MOV [pmem_find_requester_stackless_return],0
	CMP ESI,-1
	JNE psoftware_continue
		STI
		CLERR
		// We really don't want this interrupt to go to an unknown ptable, just reset at this point.
		INT 0
	psoftware_continue:
	MOV [pmem_requester_page],ESI
	XCHG EAX,EDX
	MOV EAX,[psoftware_eax]
	FINT EAX
	CMP EAX,(psoftware_interrupt_vector_end-psoftware_interrupt_vector)
	JG psoftware_end
	CMP EAX,0
	JL psoftware_end
	MOV EAX,[EAX:psoftware_interrupt_vector] // get an int
	CMP EAX,0
	JE psoftware_end
	XCHG ESI,EBX // EBX = Which ptable to store stack for.
	SUB EBX,os_ptable_entries+1
	DIV EBX,2
	MOV [psoftware_eax],EAX
	MOV EAX,psoftware_stack_setup_finished
	JMP setup_os_stack
	psoftware_stack_setup_finished:
	MOV EAX,[psoftware_eax]
	XCHG ESI,EBX // Put EBX back, then we return ESI to original state.
	MOV ESI,[psoftware_esi]
	CALL EAX
	XCHG ESI,EBX // Store EBX in ESI, it'll be restored soon.
	MOV EBX,[pmem_requester_page]
	SUB EBX,os_program_ptables+1
	DIV EBX,2
	MOV EAX,psoftware_program_stack_restored
	JMP setup_program_stack // We are now back to being in the program stack.
	psoftware_program_stack_restored:
	XCHG ESI,EBX // Restore EBX, ESI gets restored properly in psoftware_end
	psoftware_end:
	MOV EAX,[pmem_requester_page]
	MOV [pmem_requester_page],[EAX] // Deref this
	MUL [pmem_requester_page],128
	MOV EAX,[psoftware_eax]
	MOV ESI,[psoftware_esi]
	MOV DS,[psoftware_ds]
STI
CLERR
IRETP [CS:pmem_requester_page]

psoftware_interrupt_vector:
DB palloc,pfree,pspawn//,pexit
ALLOC 28 // 28 free entries.
psoftware_interrupt_vector_end:

setup_os_stack_ebx:
DB 0

setup_os_stack:
	// EAX = Ptr to return to, because we can't *call* this if we're switching stacks now can we?
	// EBX = Which program to store this stack's state for.
	MOV [setup_os_stack_ebx],EBX
	MUL EBX,3 // Size of stack metadata
	MOV [EBX:os_program_stacks],SS
	INC EBX
	MOV [EBX:os_program_stacks],ESP
	INC EBX
	CPUGET [EBX:os_program_stacks],9 // Stack size
	MOV EBX,[setup_os_stack_ebx]
	MOV SS,os_stack
	CPUSET 9,(os_stack_end-os_stack)
	MOV ESP,[os_sp]
JMP EAX

setup_program_stack:
	// EAX = Ptr to return to
	// EBX = Which program to load stack information for.
	MOV [os_sp],ESP
	MOV [setup_os_stack_ebx],EBX
	MUL EBX,3
	MOV SS,[EBX:os_program_stacks]
	INC EBX
	MOV ESP,[EBX:os_program_stacks]
	INC EBX
	CPUSET 9,[EBX:os_program_stacks]
	MOV EBX,[setup_os_stack_ebx]
JMP EAX

check_page_allocated:
	// ESI = PTR to page
	INC ESI
	CPUSET 25,[ESI]
	DEC ESI
RET

page_in_ptable:
	PUSH ESI
	// EDX = target page
	// ESI = ptable ptr
	// ECX = entries to check
	page_in_ptable_loop:
		INC ESI
		CMP [ESI],EDX
		INC ESI
		JE page_in_ptable_break
	LOOP page_in_ptable_loop
	page_in_ptable_break:
	POP ESI
RET

pmem_find_requester:
	// Provide EDX as PPAGE / CPUGET EDX,41 before call
	// Destroys ESI.
	MOV ESI,os_ptable_end-2
pmem_find_requester_loop:
	CALL check_page_allocated
	JE pmem_skip_ptable
	CNZ page_in_ptable  // if allocated, check it out
	JE pmem_find_requester_break // Found.
	pmem_skip_ptable:
	CMP ESI,os_program_ptables-2 // Range check
	JE pmem_find_requester_fail
	SUB ESI,2
JMP pmem_find_requester_loop

pmem_find_requester_fail:
	MOV ESI,-2
pmem_find_requester_break:
	INC ESI
RET

page_in_ptable_stackless_esi:
DB 0
page_in_ptable_stackless:
	MOV [page_in_ptable_stackless_esi],ESI
	// EDX = target page
	// ESI = ptable ptr
	// ECX = entries to check
	page_in_ptable_stackless_loop:
		INC ESI
		CMP [ESI],EDX
		INC ESI
		JE page_in_ptable_stackless_break
	LOOP page_in_ptable_stackless_loop
	page_in_ptable_stackless_break:
	MOV ESI,[page_in_ptable_stackless_esi]
JMP pmem_find_requester_stackless_page_in_ptable_return

pmem_find_requester_stackless_return:
DB 0

pmem_find_requester_stackless:
	// Provide EDX as PPAGE / CPUGET EDX,41 before call
	// Destroys ESI.
	MOV ESI,os_ptable_end-2
pmem_find_requester_loop_stackless:
	INC ESI
	CPUSET 25,[ESI]
	DEC ESI    
	JE pmem_stackless_skip_ptable
	JNZ page_in_ptable_stackless  // if allocated, check it out
	pmem_find_requester_stackless_page_in_ptable_return:
	JE pmem_find_requester_stackless_break // Found.
	pmem_stackless_skip_ptable:
	CMP ESI,os_program_ptables-2 // Range check
	JE pmem_find_requester_stackless_fail
	SUB ESI,2
JMP pmem_find_requester_loop_stackless

pmem_find_requester_stackless_fail:
	MOV ESI,-2
pmem_find_requester_stackless_break:
	INC ESI
JMP [pmem_find_requester_stackless_return]

pmem_requester_page:
DB 0

palloc:
	// EBX = number of pages to allocate
	// EBX will be returned as ptr to allocated region
	PUSH EAX
	PUSH EDX
	PUSH ECX
	PUSH ESI
	PUSH EDI
	MOV ECX,[pmem_requester_page]
	SUB ECX,os_ptable_entries
	MUL ECX,64 // Mapped address for where we're storing the (aligned to page boundaries) ptable
	MOV EDI,DS
	MOV EDX,EBX
	MOV DS,free_page_stack
	palloc_get_freepages:
		MOV EAX,[-1] // get from stack using memory stack ptr
		MOV EAX,[EAX]
		PUSH EAX
		INC [-1] // increment as this is a pop operation
	LOOPB palloc_get_freepages
	MOV EBX,EDX
	MOV EAX,126
	MOV EDX,0 // counter for how many contiguous free mappings we've found
	MOV DS,ECX // should be start of the target ptable
	palloc_find_unmapped_section:
		CMP [EAX],0
		INC EDX
		JE palloc_unmapped_page
		MOV EDX,0
		palloc_unmapped_page:
		CMP EDX,EBX
		JE palloc_find_unmapped_section_break // Found a contiguous section.
		SUB EAX,2
		CMP EAX,0
		JE palloc_fail_allocate
	JMP palloc_find_unmapped_section
	palloc_fail_allocate:
		MOV DS,EBX
		MOV EBX,-1
		JMP palloc_end // failed to find a section large enough.
	palloc_find_unmapped_section_break:
	MOV EDI,EAX // start of contiguous section.
	palloc_map_pages:
		MOV ESI,[EAX]
		BOR ESI,2 // Set remapped bit
		BAND ESI,65202 // Mask for full run level and the remapped bit.
		MOV [EAX],ESI
		INC EAX
		POP [EAX] // Map page from stack entry
		INC EAX
	LOOPB palloc_map_pages
	MOV DS,EBX
	MOV EBX,EDI
	MUL EBX,64
palloc_end:
	POP EDI
	POP ESI
	POP ECX
	POP EDX
	POP EAX
RET

// EBX = address to be freed(divisible by 128 only)
// ECX = number of pages to be freed
pfree:
	PUSH ESI
	PUSH DS
	PUSH ECX
	MOV ESI,[pmem_requester_page]
	SUB ESI,os_ptable_entries
	MUL ESI,64
	MOV DS,ESI // Now targeting requesting ptable
	DIV EBX,64 // Get the byte for the permissions mask
	POP ECX
	MOV EDX,ESP
	pfree_loop:
		BIT [EBX],4 // Check if page shouldn't be returned to stack on free
		BOR [EBX],1 // Set disabled bit
		BAND [EBX],65201 // Permissions mask with the disabled bit
		INC EBX
		JNZ pfree_destroy // Destroy the page without returning it to stack if bit 4(32) enabled.
		CMP [EBX],0 // Don't pollute the freed pages with unmapped ones.
		JE pfree_skip
		PUSH [EBX]
		pfree_destroy:
		MOV [EBX],0
		pfree_skip:
		INC EBX
	LOOP pfree_loop
	MOV DS,free_page_stack
	MOV ECX,EDX
	MOV EDX,ESP
	SUB ECX,EDX // ECX is now oldstack-newstack
	CMP ECX,0
	JE pfree_end
	pfree_push_freedpages:
		MOV EDX,[-1] // get from stack using memory stack ptr
		POP [EDX]
		DEC [-1] // decrement as this is a push operation
	LOOP pfree_push_freedpages
pfree_end:
	POP DS
	POP ESI
RET

pspawn:
CLI
	// EDX = Spawn and start, or just spawn?
	// ESI = ptr to buffer to load as program
	// EBX = program size to load
	// ECX = program stack size given(ceils to higher page)
	PUSH EBP // 1
	MOV EBP,EDX // Save EBP as the switch, it'll later take the physical page for the spawned program if nonzero.
	PUSH EDX // 2
	CPUGET EDX,41
	PUSH ESI // 3
	PUSH ECX // 4
	PUSH EBX // 5
	PUSH DS // 6
	PUSH KS // 7
	PUSH LS // 8
	// Find a free ptable in os_program_ptables
	MOV EDX,os_ptable_end-os_program_ptables
	MOV DS,os_program_ptables
	pspawn_find_free_ptable_loop:
		CMP [EDX],0
		JE pspawn_find_free_ptable_break
		DEC EDX // double decrement with loopd + this
	LOOPD pspawn_find_free_ptable_loop
	JMP pspawn_exit
	pspawn_find_free_ptable_break:
	// EDX is now a ptr to a free table local to os_program_ptables
	PUSH EAX // 9
	// Pop a page off of the free page stack to use
	MOV KS,free_page_stack
	INC [KS:-1]
	MOV EAX,[KS:-1]
	MOV DS,os_program_ptables
	MOV [EDX],2 // Set as remapped
	INC EDX
	MOV [EDX],[KS:EAX] // Put page as ptable
	// Set up the stack values for this entry.
	PUSH EDX
	DEC EDX
	MUL EDX,1.5 // DIV by 2 MUL by 3, for converting a 2 wide index to a 3 wide index to account for stack entry size.
	MOV [EDX:os_program_stacks],EBX // SS is end of requested program memory.
	INC EDX
	SUB ECX,2
	MOV [EDX:os_program_stacks],ECX // ESP is ECX-1 if empty but we need to set it to ECX-3 to pop CS,IP
	ADD ECX,2
	INC EDX
	MOV [EDX:os_program_stacks],ECX // ESZ is ECX
	// We need to find a way to write 0,0 to the stack but I'll do that later.
	POP EDX // EDX is now restored to original value.
	CPUSET 25,EBP
	JZ pspawn_skip_storage
		MOV EBP,EDX
		ADD EBP,os_program_ptables
	pspawn_skip_storage:
	POP EAX // 8
	DEC EDX
	ADD EDX,(os_program_ptables-os_ptable_entries)
	MUL EDX,64 // Get virtual address to mapped page table so we can set it up.
	MOV DS,0
	PUSH EDX // 9
	MOV [EDX],1 // Page permission of default page now disabled
	INC EDX
	MOV [EDX],0 // No mapped index.
	INC EDX
	// Now we need to map enough pages to fit both the stack size, and the program's bytes.
	PUSH EBX // 10
	ADD EBX,ECX
	DIV EBX,128
	FCEIL EBX
	// Now EBX is the number of pages required to fit all of the program's requested memory.
	// Begin page setup.
	PUSH EAX // 11
	PUSH EDX // 12
	pspawn_map_program_pages:
		MOV [EDX],2 // Remapped.
		INC EDX
		INC [KS:-1]
		MOV EAX,[KS:-1]
		MOV R5,EAX
		MOV R6,[KS:EAX]
		MOV [EDX],[KS:EAX]
		INC EDX
	LOOPB pspawn_map_program_pages
	// We need to zero all of the other pages in here actually.
	// Do this later maybe?
	POP LS // 11 LS is now the spawned ptable
	POP EAX // 10
	POP EBX // 9
	// Now we need to copy the program to the pages from the pointer provided.
	MOV R5,LS
	PUSH ESI // 10
	MOV EDX,[pmem_requester_page] // Get the requester page, this is raw right now.
	// Requester page is the absolute address of the page's mapping in os_program_ptables.
	DIV ESI,128 // Which page entry to check for this virtual address.
	FINT ESI
	INC ESI // 1 index this, to account for default page.
	MUL ESI,2
	SUB EDX,os_ptable_entries+1
	MUL EDX,64 // Get address to the remapping of the requester ptable.
	PUSH EDX // 11
	ADD EDX,ESI
	MOV KS,EDX // we don't need the free page stack anymore, KS will be the requester ptables offset
	POP EDX // 10
	POP ESI // 9
	POP EDX // 8
	PUSH EDI // 9
	MOV EDI,0
	MOD ESI,128
	// Load page mapping.
	MOV [os_dtransfer_esi+1],[KS:1]
	ADD KS,2
	MOV [os_dtransfer_edi+1],[LS:1]
	ADD LS,2
	pspawn_copy_loop:
		MOV [EDI:((os_dtransfer_edi-os_ptable_entries)*64], // edi page
			[ESI:((os_dtransfer_esi)-os_ptable_entries)*64] // esi page
		INC ESI
		INC EDI
		CMP ESI,128
		JE pspawn_reset_esi
		pspawn_return_esi:
		CMP EDI,128
		JE pspawn_reset_edi
		pspawn_return_edi:
	LOOPB pspawn_copy_loop
	JMP pspawn_finished_copy
	pspawn_reset_esi:
	MOV ESI,0
	// shift source page
	MOV [os_dtransfer_esi+1],[KS:1]
	ADD KS,2
	JMP pspawn_return_esi
	pspawn_reset_edi:
	MOV EDI,0
	// shift destination page
	MOV [os_dtransfer_edi+1],[LS:1]
	ADD LS,2
	JMP pspawn_return_edi
	pspawn_finished_copy:
	POP EDI // 8
	CPUSET 25,EBP
	JZ pspawn_skip_set
		MOV [pmem_requester_page],EBP // Now we'll jump to the spawned program after.
	pspawn_skip_set:
pspawn_exit:
	POP LS // 7
	POP KS // 6
	POP DS // 5
	POP EBX // 4
	POP ECX // 3
	POP ESI // 2
	POP EDX // 1
	POP EBP // 0
RET
// 4 and up are for remapping to other ptables
os_ptable:
DB 0,0 // Default page, permissions here are used if page < 0 or > PTBE. Not disabled so mem and port access can happen from OS.
os_ptable_entries:
DB 0,0 // 0-127 1
DB 0,0 // 128-255 2
DB 0,0 // 256-383 3
DB 0,0 // 384-511 4
DB 0,0 // 512-639 5
DB 0,0 // 640-767 6 
DB 0,0 // 768-895 7
DB 0,0 // 896-1023 8
DB 0,0 // 1024-1151 9
DB 0,0 // 1152-1279 10
os_program_ptables:
DB 2,32 // 1280-1407 default map as 4096
DB 0,0 // 1408-1535
DB 0,0 // 1536-1663
DB 0,0 // 1664-1791
os_ptable_end:
os_dtransfer_map: // For setting up buffer/entire page copies.
os_dtransfer_esi: // Source page
DB 2,0 // 1792-1919
os_dtransfer_edi: // Destination page
DB 2,0 // 1920-2047

os_program_stacks:
ALLOC 4*3
os_program_stacks_end:

// Stack for currently free pages.
free_page_sp:
DB 63
free_page_stack:
ALLOC 64
end_free_page_stack:

// Stack for OS operations.
os_sp:
DB 15
os_stack:
ALLOC 16
os_stack_end:

CODE
CPUSET 37,os_ptable
//CPUSET 38,(os_ptable_end-os_ptable)/2
CPUSET 38,64 // 64 page entries, so we won't have to switch the size when we enter a program.
CPUSET 52,(smint_end-smint)/4
MOV ESP,(os_stack_end-os_stack)-1
MOV SS,(os_stack)
CPUSET 9,(os_stack_end-os_stack)
LIDTR smint
STEF
STM
STI


// Get the free pages for popping.
MOV EDI,(free_space/128)
MOV DS,free_page_stack
generate_free_pages:
	MOV EDX,[-1]
	MOV [EDX],EDI
	INC EDI
	DEC [-1]
	CMP [-1],0
	MOV PORT0,EDX
JG generate_free_pages
MOV DS,0
MOV EDI,0
MOV EDX,0
PUSH 0 // CS
PUSH 0 // IP
IRETP 4096
pre_free_space:
ORG 1152
free_space:
ORG 4096

	]],
	["palloc_spawn_example.txt"] = [[
#include <palloc.txt>
ptable:
DB 0,0
DB 2,(program/128)
z:
DB 2,(program2/128)
ALLOC 122

OFFSET -4224
program:
MOV ESI,program2
MOV EBX,128 // Code size
MOV ECX,128 // Stack size(allocates but doesn't set up for you)
MOV EDX,1 // 1 = Run spawned program immediately after, 0 = Load but don't run spawned program immediately.
MOV ESI,program2
MOV EAX,2
INT 20 // PSPAWN
p1_loop:
INC R5
JMP p1_loop
ALLOC 102
program2:
INC R4
MOV R6,ESP
MOV R7,SS
JMP 0
]]
}

function Test.Run(CPU,TestSuite)
	CPU.RAMSize = 32768
	CPU.ROMSize = 32768
	CPU.Frequency = 1e6
	TestSuite:Deploy(CPU,TestSuite:LoadFile("palloc_spawn_example.txt"),Test.CompileError)
	CPU.Clk = 1
	for i = 0, 1024*1024 do
		CPU:RunStep()
	end
	-- On false, will cause test to fail with message
	assert(not CPU.VMStopped,"VM Stopped at end of execution, likely an unhandled interrupt caused an error.")
end

function Test.CompileError(msg)
	assert(false,"compile time error: " .. msg)
end

return Test