## 1. task 1 ##
A player - client model
client calculate the optimal solution for I/O blocks.
               
```
          Host                        tetris.v                      calc.v
    +-------------+ Receive block +-------------+               +-------------+   
    |             |- - - - - - - >|             |               |             |
    +-------------+               +-------------+               +-------------+
           |                             |                             |
           v           Request           v                             |      
    +-------------+   top 2 rows  +-------------+                      |
    |             |<- - - - - - - |             |                      |
    +-------------+               +-------------+                      |
           |                             |                             |
           |           Recieve           v                             |
    +-------------+   top 2 rows  +-------------+                      |
    |             | - - - - - - ->|             |                      |
    +-------------+               +-------------+                      |
           |                             |                             |
           |                             |                             |
           |                             |                             |
           |                             v          Transfer           |            
           |                      +-------------+  top 2 rows   +-------------+               
           |                      |             |- - - - - - -> |             |
           |                      +-------------+               +-------------+
           |                             |                             |
           |                             v          Recieve            v
           |                      +-------------+ optimal sol.  +-------------+   
           |                      |             |<- - - - - - - |             |   
           |                      +-------------+               +-------------+
           |                             |
           v          Set block          v
    +-------------+to optimal sol.+-------------+
    |             |<--------------|             |
    +-------------+               +-------------+  
```

Chip area for top module '\tetris': 2623.766400 ( < 5000)

Test Result: >500 line clears.


## 2. task 2 ##
A player - board - client model.

Board saves the current Tetris board and return this to a client,

Client calculate the optimal solution for any arbitrary board, block placement combinations.

```
          Host                        tetris.v                      calc.v               
    +-------------+ Receive block +-------------+               +-------------+   
    |             |- - - - - - - >|             |               |             |
    +-------------+               +-------------+               +-------------+
           |                             |                             |
           v           Request           v                             |      
    +-------------+   each row    +-------------+                      |
/---|             |<- - - - - - - |             |<-\  Save at          |
|   +-------------+               +-------------+  |   board_save.v    |
|          |                             |--------------\              |
|          |           Recieve           v         |    |              |
|   +-------------+   each row    +-------------+  |    |              |
\-->|             | - - - - - - ->|             |--/    |              |
    +-------------+               +-------------+       |              |
           |                             |              |              |
           |                             |              |              |
           |                             |          Transfer           |
           |                             v          all rows           |            
           |                      +-------------+       \       +-------------+               
           |                      |             |- - - - - - -> |             |
           |                      +-------------+               +-------------+
           |                             |                             |         
           |                             |                             v
           |                             |                      +-------------+        board_nextsim.v
           |                             |              /------>|             |- - - - - - - - - - - \  
           |                             |              |       +-------------+        Simulate      |   
           |                             |              |              |          the next placement |                          
           |                             |              |              v             of the block    |  
           |                             |              |       +-------------+                      |
           |                             |              |       |             |- - - - - - - - - - - /
           |                             |              |       +-------------+               
           |                             |              |              |                        
           |                             |              |              v
           |                             |              |       +-------------+          board_analy.v                          
           |                             |              |       |             |- - - - - - - - - - - \  
           |                             |              |       +-------------+        Evaluate      |  
           |                             |              |              |          the next placement |                    
           |                             |              |              v             of the block    |  
           |                             |              |       +-------------+(cf. genetic_train.py)|  
           |                             |              \--=----|             |< - - - - - -- - - - -/  
           |                             |           Iterate    +-------------+                                            
           |                             |          all cases          |                        
           |                             |                             |
           |                             |                             |   Determine what is the 
           |                             |                             |     optimal solution
           |                             |                             |
           |                             |                             |                        
           |                             v                             v
           |                      +-------------+ optimal sol.  +-------------+   
           |                      |             |<- - - - - - - |             |   
           |                      +-------------+               +-------------+
           |                             |
           v          Set block          v
    +-------------+to optimal sol.+-------------+
    |             |<--------------|             |
    +-------------+               +-------------+  
```

Chip area for top module '\tetris': 204513.644800 ( < 300000)

Test Result

1.txt) 3524 lines

![image](https://github.com/user-attachments/assets/81267eb0-98e3-4440-8517-864f21017345)

2.txt) 426 lines

![image](https://github.com/user-attachments/assets/8752f878-a777-438a-ba2c-f7ce37c181b7)

3.txt) 1925 lines

![image](https://github.com/user-attachments/assets/72278b0a-9836-4a7c-a235-62890786f8a0)

random) 1866 lines

![image](https://github.com/user-attachments/assets/33049869-a112-4689-b1a9-af17b4ddbb3b)

## 3. Environment ##
Same as LD24_final_project distribution.

SKY130 LIBRARY = sky130_fd_sc_hd__tt_025C_1v80.lib 

Verilog Version = 2005