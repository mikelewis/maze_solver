# File:		maze.asm
# Author:	Mike Lewis(mdl3035)
# Description:	This program takes an unsolved maze, with both a start
#				and end postion, and returns the solved maze.


#CONSTANTS

#syscall codes
PRINT_INT = 	1
PRINT_STRING = 	4
PRINT_CHAR = 11
READ_INT = 	5
READ_STRING = 8
EXIT = 		10

#ascii characters
WALL_CHAR = 35
SPACE_CHAR = 32
START_CHAR = 83
EXIT_CHAR = 69
CRUMB_CHAR = 46

#facing direction
UP = 0
RIGHT = 1
DOWN = 2
LEFT = 3

	.data

pose: #init to start space
	.word 0, 0, UP #0 = UP, 1 = RIGHT, 2 = DOWN, 3 = LEFT

board_data:
	.word 0, 0 #num_rows, num_cols


banner1:
	.asciiz "===\n"
banner2:
	.asciiz "=== Maze Solver\n"
banner3:
	.asciiz "=== by\n"
banner4:
	.asciiz "=== Mike Lewis\n"

input_string:
	.asciiz "Input Maze:\n\n"

solution_string:
	.asciiz "Solution:\n\n"

board:
	.space 80 * 80 

board_copy:
	.space 80 * 80 #MAX SIZE

new_line:
	.asciiz "\n"

read_in_string:
	.space 82

	.text
	.align 2
	.globl main


#
# Main:		MAIN PROGRAM
#
# Description: This is the main logic for the program
#			   It prints out the banner, followed by the unsolved maze.
#			   It than solves the maze, followed by printing the solved 
#			   mazed.

main:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)

	jal read_board_in

	li 	$v0, PRINT_STRING
	la $a0, banner1
	syscall	
	li 	$v0, PRINT_STRING
	la $a0, banner2
	syscall	
	li 	$v0, PRINT_STRING
	la $a0, banner3
	syscall	
	li 	$v0, PRINT_STRING
	la $a0, banner4
	syscall	
	li 	$v0, PRINT_STRING
	la $a0, banner1
	syscall	
	li 	$v0, PRINT_STRING
	la $a0, new_line
	syscall	

	li 	$v0, PRINT_STRING
	la $a0, new_line
	syscall	


	li 	$v0, PRINT_STRING
	la $a0, input_string
	syscall	

	la $a0, board
	jal print_board

	li 	$v0, PRINT_STRING
	la $a0, new_line
	syscall	

	li 	$v0, PRINT_STRING
	la $a0, new_line
	syscall	



	li 	$v0, PRINT_STRING
	la $a0, solution_string
	syscall	

	#copy board

	jal copy_board

	jal solve

	la $a0, board
	jal print_board


main_done:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra

#
# Name:		Solve
#
# Description: The main solver for maze.asm. This will solve the maze by
#			   using a Depth First Search that finds it's way to the end,
#			   while dropping breadcrumbs. It will than backtrack to the 
#  			   to the start, while dropping '.' to mark the solved path.

solve:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)


	li $s4, 0 #init the turning counter

step_2:
check_contents:

	la $s0, pose
	lw $t0, 0($s0) #x
	lw $t1, 4($s0) #y

	move $a0, $t0
	move $a1, $t1
	la $a2, board_copy
	jal get_at_xy

	li $t2, EXIT_CHAR
	beq $v0,  $t2, step_5
	j step_3

step_3:
check_next_char:

	la $a0, board
	jal get_next_char

	li $t0, SPACE_CHAR

	beq $v0, $t0, step_3aa #If the curr location on the main board
							#is a space
	li $t0, EXIT_CHAR
	beq $v0, $t0, step_5
	j step_3b

step_3aa:

	la $a0, board_copy
	jal get_next_char 
	

	# If the current location in the board_copy is a bread crumb
	# go onto step_3b
	li $t1, UP
	beq $v0, $t1, step_3b
	li $t1, RIGHT
	beq $v0, $t1, step_3b 
	li $t1, DOWN
	beq $v0, $t1, step_3b 
	li $t1, LEFT
	beq $v0, $t1, step_3b

	#Otherwise go to step_4
	j step_4



step_3b:

	la $s0, pose
	lw $t0, 0($s0) #x
	lw $t1, 4($s0) #y
	lw $t2, 8($s0) # DIR

	li $t3, 4
	beq $s4, $t3, step_3c # You turned 4 times, backtrace time

	#Otherwise rotate your self, and try again
	addi $t2, $t2, 1
	li $t5, 4
	beq $t2, $t5, reset_direction
	j done_reset_direction
reset_direction:
	li $t2, 0
done_reset_direction:

	addi $s4, $s4, 1
	sw $t2, 8($s0)

	j step_3 

	

step_3c: #BACKTRACING

	la $s0, pose
	lw $a0, 0($s0) #x
	lw $a1, 4($s0) #y

	la $a2, board_copy
	jal get_at_xy #at this point, v0 should be a breadcrumb
	move $t6, $v0

	#move in that breadcrumb direction
	
	move $a0, $t6
	jal move_one_space_towards
	li $s4, 0 #reset turning counter
	j step_3



step_4:
move_space:

	li $s4, 0 # reset
	jal move_one_space_towards_curr

	la $s0, pose
	lw $a0, 0($s0) #x
	lw $a1, 4($s0) #y
	lw $s1, 8($s0) #dir
	la $a2, board_copy

	li $t0, UP
	beq $s1, $t0, set_breadcrumb_down
	li $t0, RIGHT
	beq $s1, $t0, set_breadcrumb_left
	li $t0, DOWN
	beq $s1, $t0, set_breadcrumb_up
	li $t0, LEFT
	beq $s1, $t0, set_breadcrumb_right

set_breadcrumb_up:
	li $a3, UP
	j done_determine_dir
set_breadcrumb_right:
	li $a3, RIGHT
	j done_determine_dir
set_breadcrumb_down:
	li $a3, DOWN
	j done_determine_dir
set_breadcrumb_left:
	li $a3, LEFT
	j done_determine_dir

done_determine_dir:

	jal write_at_xy
	j step_2
	
step_5:
found_end:

	#Load init crumb
	la $a0, board
	li $a1, CRUMB_CHAR 
	jal write_at_curr
	


step_5a:
	la $a0, board_copy
	jal get_at_curr #v0 should be breadcrumb


	la $s0, pose
	sw $v0, 8($s0) #change directions to follow breadcrumb

	jal move_one_space_towards_curr


step_5b:
	la $a0, board
	jal get_at_curr

	li $t0, START_CHAR
	beq $v0, $t0, done_solve
	
	#drop crumb on the main map and go to step 5a
	

	la $a0, board
	li $a1, CRUMB_CHAR 
	jal write_at_curr
	

	j step_5a

	

done_solve:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra

#
# Name:		Move One Space Towards Current
#
# Description: This routine moves the pose one space towards the current
# direction.
#

move_one_space_towards_curr:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)

	la $s0, pose
	lw $a0, 8($s0) #current direction

	
	jal move_one_space_towards


done_move_one_space_towards_curr:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12   	# deallocate space for the return address
	jr 	$ra		# return from main and exit




#
# Name:	Move one Space Towards
#
# Description: Moves the pose one space towards the given direction
#
# Arguments: a0 - Direction to move in
#

move_one_space_towards:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)

	la $s0, pose
	lw $t0, 0($s0) #x
	lw $t1, 4($s0) #y

	li $t2, UP
	beq $a0, $t2, move_one_space_up
	li $t2, RIGHT
	beq $a0, $t2, move_one_space_right
	li $t2, DOWN
	beq $a0, $t2, move_one_space_down
	li $t2, LEFT
	beq $a0, $t2, move_one_space_left


move_one_space_up:
	addi $t0, $t0, -1
	sw $t0, 0($s0)	

	j done_move_one_space_towards
move_one_space_right:
	addi $t1, $t1, 1
	sw $t1, 4($s0)	
	
	j done_move_one_space_towards
move_one_space_down:
	addi $t0, $t0, 1
	sw $t0, 0($s0)	
	
	j done_move_one_space_towards
move_one_space_left:
	addi $t1, $t1, -1
	sw $t1, 4($s0)	

	j done_move_one_space_towards

done_move_one_space_towards:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra



#
# Name: Get Next Char
#
# Description: Get the next character from the current location in the pose.
#
# Arguements: a0 - board
#
get_next_char:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)
	
	la $s0, pose
	lw $t0, 0($s0) #x
	lw $t1, 4($s0) #y
	lw $s1, 8($s0) #dir
	
	li $t5, UP
	beq $s1, $t5, get_up
	li $t5, RIGHT
	beq $s1, $t5, get_right
	li $t5, DOWN
	beq $s1, $t5, get_down
	li $t5, LEFT
	beq $s1, $t5, get_left

get_up:

	addi $t0, $t0, -1
	move $a0, $t0
	move $a1, $t1
	jal get_at_xy #v0 is set
	
	j done_get_next_char
get_right:

	addi $t1, $t1, 1
	move $a0, $t0
	move $a1, $t1
	jal get_at_xy #v0 is set

	j done_get_next_char
get_down:
	addi $t0, $t0, 1
	move $a0, $t0
	move $a1, $t1

	jal get_at_xy #v0 is set

	j done_get_next_char
get_left:

	addi $t1, $t1, -1
	move $a0, $t0
	move $a1, $t1
	jal get_at_xy #v0 is set
	
	j done_get_next_char

done_get_next_char:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra


#
# Name: Copy Board
#
# Description: Copy the original board to board_copy. This is made for the
# 'scratch copy'
#

copy_board:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)

	la  $s0, board
	la $s1, board_copy 
	li $t5, 0 #counter
	
	la $t6, board_data
	lw $t0, 0($t6) #num rows
	lw $t1, 4($t6) #num cols
	mul $t3, $t0, $t1 


	
loop_copy:
	beq $t5, $t3, done_copy_board 
	
	lb $t4, 0($s0)
	sb $t4, 0($s1)


	addi $t5, $t5, 1
	addi $s0, $s0, 1
	addi $s1, $s1, 1
	j loop_copy


done_copy_board:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra

#
# Name: Write at Current
#
# Description: Writes the value in a1 at the current location to a0, the
# board.
#
# Arguements:
#				a0 - board
#				a1 - what
#

write_at_curr:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)

	move $a2, $a0
	move $a3, $a1

	la $s0, pose
	lw $a0, 0($s0) #x
	lw $a1, 4($s0) #y

	jal write_at_xy

done_write_at_curr:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra




#
# Name: Write at XY
#
# Description: Write the value at a3, to a0 (x) a1 (y) to a2 (board)
#
# Arguements:
#				a0 - x
#				a1 - y
#				a2 - board
#				a3 - what to write
#

write_at_xy:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)


	move $s0, $a2 #board

	la $t6, board_data
	lw $t0, 4($t6) #num cols

	mul $t1, $a0, $t0

	add $t1, $t1, $a1

	add $s1, $s0, $t1 #s1 is address to write to

	sb $a3, 0($s1)


done_write_at_xy:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra

#
# Name: Get At Current
#
# Description: Get the value at the current location for board a0
#
# Arguments: a0 - board
#

get_at_curr:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)

	move $a2, $a0

	la $s0, pose
	lw $a0, 0($s0) #x
	lw $a1, 4($s0) #y

	jal get_at_xy

done_get_at_curr:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra


#
# Name: Get at XY
#
# Description: Get the value at a0 (x) a1(y) on a2(board)
#
# Arguements:
# 				a0 - x
# 				a1 - y
# 				a2 - board
#

get_at_xy:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)

	move $s0, $a2


	la $t6, board_data
	lw $t0, 4($t6) #num cols

	mul $t1, $a0, $t0

	add $t1, $t1, $a1

	add $s1, $s0, $t1

	lb $t2, 0($s1)

	#return value
	move $v0, $t2


done_print_at_xy:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra


#
# Name: Print Board
#
# Description: Print the given board (a0)
#
# Arguments: a0 - Board to print
#

print_board:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)

	move $s0, $a0
	li $t0, 0 #col counter
	li $t1, 0 #row counter

row_loop:


	la $t6, board_data
	lw $t3, 4($t6) #num cols
	beq $t0, $t3, end_row_loop

	lb $t5, 0($s0) #curr character
	slti $t6, $t5, 4

	bne $t6, $zero, print_int
	j print_char

print_int:
	li 	$v0, PRINT_INT
	move $a0, $t5
	syscall	

print_char:

	li 	$v0, PRINT_CHAR
	move $a0, $t5
	syscall	


	addi $t0, $t0, 1
	addi $s0, $s0, 1
	j row_loop

end_row_loop:
	addi $t1, $t1, 1



	la $t6, board_data
	lw $t3, 0($t6) #num rows
	beq $t1, $t3, done_print_board

	#print new line
	li 	$v0, PRINT_STRING
	la $a0, new_line
	syscall	


	li $t0, 0
	j row_loop


done_print_board:

	li 	$v0, PRINT_STRING
	la $a0, new_line
	syscall	


	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra


#
# Name: Print Current Location
#
# Description: Print the current location stored in pose
#

print_current_location:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)
	
	la $s0, pose
	lw $t0, 0($s0)
	lw $t1, 4($s0)
	lw $t2, 8($s0)

	li $v0, PRINT_STRING
	la $a0, new_line
	syscall


	li $v0, PRINT_INT
	move $a0, $t0
	syscall

	li $v0, PRINT_STRING
	la $a0, new_line
	syscall



	li $v0, PRINT_INT
	move $a0, $t1
	syscall

	li $v0, PRINT_STRING
	la $a0, new_line
	syscall



	li $v0, PRINT_INT
	move $a0, $t2
	syscall

	li $v0, PRINT_STRING
	la $a0, new_line
	syscall



done_print_current_location:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra

#
# Name: Read board in
#
# Description: Reads the current board in from STIN
#

read_board_in:
	addi 	$sp, $sp, -12  	# allocate space for the return address
	sw 	$ra, 8($sp)	# store the ra on the stack
	sw 	$s1, 4($sp)
	sw 	$s0, 0($sp)

	la $s0, board_data
	la $s1, board
	
	#read sizes

	la $v0, READ_INT
	syscall
	sw $v0, 0($s0)

	la $v0, READ_INT
	syscall
	sw $v0, 4($s0)

	#read board

	lw $t2, 0($s0) # height
	lw $t3, 4($s0) # width
	li $t1, 0 #height_counter
read_board_loop:

	beq $t1, $t2, end_read_board_loop

	la $v0, READ_STRING
	la $a0, read_in_string
	li $a1, 82
	syscall
	
	la $t5, read_in_string
	li $t4, 0 #row counter
read_row:
	beq $t4, $t3, end_read_row

	lb $t6, 0($t5)
	sb $t6, 0($s1)
	
	la $t7, START_CHAR
	beq $t6, $t7, record_start_location
	j end_record_start_location

record_start_location:
	
	la $t7, pose
	
	sw $t1, 0($t7)
	sw $t4, 4($t7)

end_record_start_location:


	addi $t5, $t5, 1 #goto next char
	addi $t4, $t4, 1
	addi $s1, $s1, 1 #goto next board char
	j read_row
end_read_row:

	addi $t1, $t1, 1
	li $t4, 0 #reset row counter
	j read_board_loop
	
end_read_board_loop:


done_read_board_in:
	lw 	$ra, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 12
	jr 	$ra

