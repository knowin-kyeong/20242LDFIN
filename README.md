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
|   +-------------+               +-------------+  |   board_save.v     |
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

Chip area for top module '\tetris': 115072.864000 ( < 300000)

Test Result: ~ 178 Line clears (Expected value in genetic_train.py, limited to 500 blocks) 

(Best = 621 Line clears)
![image](https://github.com/user-attachments/assets/cc557717-5e13-4d69-9e30-b51a4b73744c)

## 3. Environment ##
Same as LD24_final_project distribution.

SKY130 LIBRARY = sky130_fd_sc_hd__tt_025C_1v80.lib 

Verilog Version = 2005