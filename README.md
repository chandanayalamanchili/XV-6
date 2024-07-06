                                                                 MINI PROJECT-2
                                                              SCHEDULING POLICIES
FIRST COME FIRST SERVE:
1. Modified struct proc
In proc.h, we added a new field to the struct proc definition to keep track of the time at which a process arrives. We introduced int ctime (creation time) to record the order of process arrival.
2. FCFS Scheduler
We modified the existing Void Scheduler function which initially executes Round Robin mechanism to follow FCFS mechanism when FCFS flag is used.
This function ensures FCFS behavior by always selecting the process with the lowest creation time. It maintains fairness in the system by allowing processes to run in the order they were created, without any preemption.
The detailed implementation of the function is as follows:
      Initialization:
        ◦ It starts by initializing some necessary variables and data structures, including the CPU (struct cpu) and setting the currently executing process (c->proc) to 0 (indicating no process is currently running).
       Avoiding Deadlock:
        ◦ It turns on and then off hardware interrupts (intr_on and intr_off) to ensure that devices can interrupt. This step is crucial for avoiding potential system deadlocks.
       Selecting the Next Process:
        ◦ The for loop iterates through the array of processes (struct proc) to find the next process to run.
        ◦ It maintains two important variables:
            ▪ selected: A pointer to the currently selected process (initially set to 0).
            ▪ min_ctime: A variable storing the minimum creation time encountered so far, initialized to a very high value (__INT_MAX__) to ensure that the first process found will have a lower creation time.
        ◦ Within the loop, it acquires the lock for each process to prevent race conditions and checks if the process is in the RUNNABLE state. If it is:
            ▪ It compares the process's creation time (p->ctime) with the current minimum creation time (min_ctime).
            ▪ If the process's creation time is lower (i.e., it arrived earlier), it updates min_ctime and sets selected to point to this process.


       Running the Selected Process:
        ◦ If a suitable selected process is found, it acquires the lock for that process and checks if it's still in the RUNNABLE state (as the process's state may have changed due to race conditions).
        ◦ If the process is still RUNNABLE, it marks it as RUNNING, assigns it to the CPU (c->proc = selected), and performs a context switch (swtch) to execute the selected process.
        ◦ After the process completes execution or yields the CPU voluntarily, it returns to this loop, and the next process in the FCFS order is selected.
       Release Lock and Continue:
        ◦ Once the selected process has run or yielded, it releases the lock for that process (release(&selected->lock)).
        ◦ The loop continues to iterate, selecting the next process based on FCFS.
3.Makefile Flag
In the Makefile, we added a flag to indicate that we want to use the FCFS scheduler. This allows us to compile xv6 with the FCFS scheduling logic enabled.
MULTI LEVEL FEEDBACK QUEUE:
1.Modified proc.h
intialise the required variables in proc.h
2.MLFQ Scheduler
We modified the existing Void Scheduler function  to follow MLFQ mechanism when MLFQ flag is used.
This scheduler organizes processes into multiple priority queues and uses aging to promote processes to higher-priority queues to prevent starvation.
      Initialization:
        ◦ The scheduler starts by initializing some variables and structures. struct cpu *c represents the CPU, and c->proc is set to 0 to indicate that there is currently no running process.
       Interrupt Handling:
        ◦ intr_on() is called to enable interrupts. This allows devices to interrupt the CPU, ensuring that the system remains responsive.
       Aging:
        ◦ The code iterates through all processes (struct proc *p) to check if any process in the RUNNABLE state has exceeded a defined wait time (limit > wlt). If a process has waited too long, it is moved to a lower-priority queue, and its quantum is updated.
       Process Selection:
        ◦ The code selects the next process to run based on priority. It maintains the variables proc_chose to track the chosen process and l_queue to store the lowest priority queue with runnable processes.
        ◦ It iterates through all processes again and compares their priority and last execution times to select the most suitable process. The process with the highest priority (cqueue value) and the earliest execution time (en_time) is chosen.
       Running the Process:
        ◦ Once a process is chosen, it is acquired and its state is checked to ensure it is still RUNNABLE. If it is, the process is marked as RUNNING, and its context is switched to execute on the CPU.
        ◦ Timing information is updated, including the process's execution time and quantum utilization.
3.Makefile flag
In the Makefile, we added a flag to indicate that we want to use the MLFQ scheduler. This allows us to compile xv6 with the MLFQ scheduling logic enabled.
4.Changes in trap.c
Include the code snippet in usertrap and kerneltrap functions which dynamically manages the time-slicing behavior of processes in the MLFQ scheduler, ensuring that processes move to lower priority queues if they consume their allotted time-slice, thus preventing starvation and promoting fairness in process execution. The time-slice values are defined according to priority levels, allowing the scheduler to allocate CPU time effectively to different types of processes.
Implementation of the snippet:
    1. struct proc *p = myproc();: This line retrieves a pointer to the current process (struct proc) using the myproc() function. In a multitasking operating system, there can be multiple processes running simultaneously, and this line ensures that we are working with the properties of the current process.
    2. int a = ticks - p->en_time;: This line calculates the amount of time (in timer ticks) that the current process has been running since its last execution. It subtracts the stored en_time (entry time) of the process from the current system time, represented by ticks.
    3. int z = p->cqueue;: The variable z represents the priority queue level to which the current process belongs. It is obtained from the cqueue attribute of the process's struct proc.
    4. int time_slice;: This variable will be used to store the appropriate time-slice value based on the process's priority level.
    5. The switch statement: This block defines the time-slice values for different priority levels within the MLFQ scheduler. The z variable determines which priority level the process belongs to, and based on this value, the corresponding time_slice is set.
        ◦ For Priority 0 (z == 0), a time-slice of 1 timer tick is set.
        ◦ For Priority 1 (z == 1), a time-slice of 3 timer ticks is set.
        ◦ For Priority 2 (z == 2), a time-slice of 9 timer ticks is set.
        ◦ For Priority 3 (z == 3), a time-slice of 15 timer ticks is set.
       If z doesn't match any of these values (which should not happen if the priority levels are correctly managed), it defaults to a time-slice of 1 timer tick.
    6. if (a > time_slice) {: This conditional check compares the time the process has been running (a) with its assigned time-slice (time_slice). If the process has exceeded its time-slice, the following actions are taken:
        ◦ p->qtic[z] += a;: The qtic array of the process is updated with the accumulated running time at its current priority level z. This helps in tracking how much CPU time the process has consumed at each priority level.
        ◦ if (z < 3) { z++; }: If the process has not yet reached the lowest priority level (Priority 3), it is moved to the next lower priority queue by incrementing z. This is an essential part of MLFQ scheduling, where processes are demoted to lower priority queues if they consume too much CPU time.
        ◦ p->en_time = ticks;: The en_time of the process is updated to the current system time (ticks), indicating that it is starting a new time-slice.
        ◦ p->cqueue = z;: The cqueue attribute of the process is updated to reflect its new priority queue, which is now z.


COMPARISION OF ROUND ROBIN, FCFS AND MLFQ:
ROUND ROBIN : 
   Average Waiting Time =  153
   Average Running Time =  13
FCFS : 
   Average Waiting Time =  126
   Average Running Time =  13
MLFQ : 
   Average Waiting Time =  152
   Average Running Time =  13


THE REPORT FOR NETWORKING PART IS IN THE README PRESENT IN NETWORKS FOLDER
