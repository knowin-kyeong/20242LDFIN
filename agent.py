# Author: Thomas Young
# Modified by Juwon Seo (knowin-kyeong)
import numpy, random

from tetrissim import TetrisApp
import tetrissim

# color mapping
COLOR_MAP = tetrissim.COLOR_MAP

# The configuration
config = tetrissim.config

# block seq
seq_arr = tetrissim.seq_arr

class TetrisAI(object):

    def __init__(self, name=None, seq_type=0, seq_random=False):
        self.name = "AI" if name is None else name
        self.tetris_app = TetrisApp(seq_type=seq_type, seq_random=seq_random)

        ''' set features wanted here MAKE SURE TO CHANGE FUNCTIONS FOR EVALUATION BELOW'''
        self.features = ("max_height", "cumulative_height", "relative_height", "roughness",
                         "hole_count", "rows_cleared", "row_transition", "col_transition", "deepest_well"
                         )
        self.weights = None

    '''
      Getters and setters
    '''

    def set_board(self, board):
        self.tetris_app.set_board(board)

    def get_board(self):
        if self.tetris_app.get_board() is None:
            raise ValueError("Tetris AI does not have a board")
        return self.tetris_app.get_board()

    def set_stone(self, stone):
        self.tetris_app.set_stone(stone)

    def get_stone(self):
        if self.tetris_app.get_stone() is None:
            raise ValueError("TetrisAI does not have a stone")
        else:
            return self.tetris_app.get_stone()

    '''
      Actual AI stuff
    '''

    def get_possible_boards(self):
        if not (hasattr(self.tetris_app, "board") and hasattr(self.tetris_app, "stone")):
            raise ValueError("either board or stone do not exist for TetrisAI")

        cur_state = self.tetris_app.get_state()

        # contains all the board orientations possible with the current stone
        board_and_stones = []
        for col in range(config['cols']-1, -1, -1):
            for rot in range(4):
                self.tetris_app.set_board(cur_state["board"])
                self.tetris_app.set_stone(cur_state["stone"])
                self.tetris_app.cleared_lines = cur_state["cleared_lines"]
                self.tetris_app.drop_blocks = cur_state["drop_blocks"]
                self.tetris_app.game_over = False

                ret = self.tetris_app.move_rotation_drop(col, rot)
                if ret == 0 and not self.tetris_app.game_over:
                    action_board = (numpy.copy(self.tetris_app.get_board()))
                    action_col = col
                    action_rot = rot
                    board_and_stones.append(
                        {
                            "board": action_board,
                            "stone": numpy.copy(cur_state["stone"]),
                            "action_col": action_col,
                            "action_rot": action_rot,
                            "action_rows_cleared": self.tetris_app.cleared_lines - cur_state["cleared_lines"]
                        }
                    )

        self.tetris_app.set_board(cur_state["board"])
        self.tetris_app.set_stone(cur_state["stone"])
        self.tetris_app.cleared_lines = cur_state["cleared_lines"]
        self.tetris_app.drop_blocks = cur_state["drop_blocks"]
        self.tetris_app.game_over = False

        return board_and_stones

    def evaluate_possible_boards(self, board_and_stones):
        eval_board_and_stone = []

        for _, bs in enumerate(board_and_stones):
            eval_board_and_stone.append(
                {
                    "board": bs['board'],
                    "stone": bs['stone'],
                    "action_col": bs['action_col'],
                    "action_rot": bs['action_rot'],
                    "eval": self.eval_board(bs['board'], bs['action_rows_cleared'])
                }
            )
        return eval_board_and_stone

    def eval_board(self, board, rows_cleared):

        if not (hasattr(self, "weights")):
            raise ValueError("TetrisAI has no weights")

        ''' Make sure these function reflect the features you are using above '''
        evals = [self.get_cumulative_height(board) * self.weights['cumulative_height'],
                 self.get_roughness(board) * self.weights['roughness'],
                 self.get_hole_count(board) * self.weights['hole_count'],
                 rows_cleared * self.weights['rows_cleared'],
                 self.get_max_height(board) * self.weights["max_height"],
                 self.get_relative_height(board) * self.weights["relative_height"],
                 self.get_row_transition(board) * self.weights["row_transition"],
                 self.get_col_transition(board) * self.weights["col_transition"],
                 self.get_deepest_well(board) * self.weights["deepest_well"]
                 ]

        return {
            "cumulative_height": self.get_cumulative_height(board),
            "roughness": self.get_roughness(board),
            "hole_count": self.get_hole_count(board),
            "rows_cleared": rows_cleared,
            "max_height": self.get_max_height(board),
            "relative_height": self.get_relative_height(board),
            "row_transition": self.get_row_transition(board),
            "col_transition": self.get_col_transition(board),
            "deepest_well": self.get_deepest_well(board),
            "weights": self.weights,
            "eval_score": sum(evals)
        }

    '''
        Gets the height of each column
    '''

    def get_column_heights(self, board):
        # get the height of each column
        heights = [0 for _ in board[0]]

        for y, row in enumerate(board[::-1]):
            for x, val in enumerate(row):
                if val != 0 and val != 9:
                    heights[x] = y + 1
        return heights

    '''
        Find max height in board
    '''

    def get_max_height(self, board):
        return max(self.get_column_heights(board))

    '''
        Gets the sum of all the columns
    '''

    def get_cumulative_height(self, board):
        return sum(self.get_column_heights(board))

    '''
        Gets the difference between he shortest and tallest height
    '''

    def get_relative_height(self, board):
        column_heights = self.get_column_heights(board)
        max_height = max(column_heights)
        min_height = min(column_heights)
        return max_height - min_height

    '''
        Get roughness
        determined by summing the hight
        absolute difference between a row at i and i+1
    '''

    def get_roughness(self, board):

        levels = self.get_column_heights(board)

        roughness = 0
        for x in range(len(levels) - 1):
            roughness += abs(levels[x] - levels[x + 1])

        return roughness

    '''
        Get the number of spaces which are un reachable
        A space is un reachable if there is another piece above it
        even if you could slip the piece in from the side
    '''

    def get_hole_count(self, board):
        levels = self.get_column_heights(board)

        holes = 0
        for y, row in enumerate(board[::-1]):
            for x, val in enumerate(row):
                # if below max column height and is a zero
                if y < levels[x] and val == 0:
                    holes += 1
        return holes

    '''
        Check how many rows will be cleared in this config
    '''

    def get_row_transition(self, board):
        r_trans = 0
        max_height = self.get_max_height(board)
        for y, row in enumerate(board[::-1]):
            if y >= max_height:
                continue
            prev = (1 if (row[0] != 0 and row[0] != 9) else 0)

            for x, val in enumerate(row):
                if x == 0:
                    continue
                curr = (1 if (val != 0 and val != 9) else 0)
                if curr != prev:
                    r_trans += 1
                    prev = curr
        return r_trans

    def get_col_transition(self, board):
        c_trans = 0

        col_height = self.get_column_heights(board)
        for col_idx in range(config['cols']):
            prev = (1 if (board[config['rows']+4 -1][col_idx] != 0) else 0)
            if col_height[col_idx] <= 1:
                continue

            for y, row in enumerate(board[::-1]):
                if y == 0:
                    continue
                if y >= col_height[col_idx]:
                    break

                cur = (1 if (row[col_idx] != 0 and row[col_idx] != 9) else 0)
                if cur != prev:
                    c_trans += 1
                    prev = cur
        return c_trans

    def get_deepest_well(self, board):
        max_depth = 0
        col_height = self.get_column_heights(board)
        for col_idx in range(config['cols']):
            if col_idx > 0 and col_height[col_idx] >= col_height[col_idx - 1]:
                continue
            elif col_idx < config['cols'] - 1 and col_height[col_idx] >= col_height[col_idx + 1]:
                continue
            else:
                if col_idx == 0:
                    temp_depth = col_height[col_idx + 1] - col_height[col_idx]
                elif col_idx == config['cols'] - 1:
                    temp_depth = col_height[col_idx - 1] - col_height[col_idx]
                else:
                    temp_depth = min(col_height[col_idx - 1], col_height[col_idx + 1]) - col_height[col_idx]
                max_depth = max(max_depth, temp_depth)
        return max_depth

    def analyze_evaluate_result(self, eval_board_and_stone):
        max_eval = None
        best_ebs = None
        for _, ebs in enumerate(eval_board_and_stone):
            if max_eval is None or max_eval < ebs['eval']['eval_score']:
                max_eval = ebs['eval']['eval_score']
                best_ebs = ebs
        return best_ebs

    def play_game(self):
        score = 0

        for x in range(len(seq_arr)):
            self.tetris_app = TetrisApp(seq_type = x)

            while not self.tetris_app.game_over and self.tetris_app.drop_blocks < len(seq_arr[0]):
                self.tetris_app.new_stone()

                bs_dict = self.get_possible_boards()
                ebs_dict = self.evaluate_possible_boards(bs_dict)
                best_ebs = self.analyze_evaluate_result(ebs_dict)
                if best_ebs is not None:
                    self.tetris_app.move_rotation_drop(best_ebs['action_col'], best_ebs['action_rot'])
                else:
                    self.tetris_app.move_rotation_drop(0, 0)

            score += self.tetris_app.get_score()

        return {
            "weights": self.weights,
            "play_score": score
        }

    '''
    Creates a gene with random weights
    if seeded it creates the weights based off the seeded gene
    '''

    def set_init_weights(self, seed=None):

        self.weights = dict()

        if seed is not None:
            if not (isinstance(seed, tuple) and len(seed) == (len(self.features))):
                raise ValueError('Seed not properly formatted. Make sure it is a tuple and has {} elements'.format(
                    len(self.features)))

            for idx in range(len(self.features)):
                self.weights[self.features[idx]] = seed[idx]

        for idx in range(len(self.features)):
            self.weights[self.features[idx]] = random.uniform(-1, 1)

    def load_weights(self, weight_tuple):
        self.weights = dict()
        for fn, f in enumerate(self.features):
            self.weights[f] = weight_tuple[fn]

    def get_weights(self):
        return self.weights


if __name__ == '__main__':
    for x in range(len(seq_arr)):
        AI = TetrisAI(seq_type=x)

        # Random Initialization
        # AI.set_init_weights()

        # Pre-trained result weights
        # self.features = ("max_height", "cumulative_height", "relative_height", "roughness",
        #                 "hole_count", "rows_cleared", "row_transition", "col_transition",
        #                 "deepest_well")

        trained_best = [-0.6402616941177253, -0.9057227254992681, 0.6629232398286269, -0.30333012819140825,
                        -0.9862193439177145, -0.8224629285758067, -0.7531236446218958, -0.8199832628897716,
                        -0.21988398773744078]
        AI.load_weights(trained_best)
        # print(AI.get_weights())

        while not AI.tetris_app.game_over and AI.tetris_app.drop_blocks < len(seq_arr[0]):
            AI.tetris_app.new_stone()

            # For Debugging

            # input('Press Any key to continue')

            # ('Calculating...')
            bs_dict = AI.get_possible_boards()
            ebs_dict = AI.evaluate_possible_boards(bs_dict)
            best_ebs = AI.analyze_evaluate_result(ebs_dict)

            if best_ebs is not None:
                AI.tetris_app.move_rotation_drop(best_ebs['action_col'], best_ebs['action_rot'])

                '''
                AI.tetris_app.print_board()

                print(best_ebs['action_col'], best_ebs['action_rot'])

                print("max_height {} * weight {} = temp1 {}".format(
                    best_ebs['eval']["max_height"], best_ebs['eval']["weights"]["max_height"],
                    best_ebs['eval']["max_height"]*best_ebs['eval']["weights"]["max_height"]))

                print("cumulative_height {} * weight {} = temp2 {}".format(
                    best_ebs['eval']["cumulative_height"], best_ebs['eval']["weights"]["cumulative_height"],
                    best_ebs['eval']["cumulative_height"] * best_ebs['eval']["weights"]["cumulative_height"]))

                print("relative_height {} * weight {} = temp3 {}".format(
                    best_ebs['eval']["relative_height"], best_ebs['eval']["weights"]["relative_height"],
                    best_ebs['eval']["relative_height"] * best_ebs['eval']["weights"]["relative_height"]))

                print("roughness {} * weight {} = temp1 {}".format(
                    best_ebs['eval']["roughness"], best_ebs['eval']["weights"]["roughness"],
                    best_ebs['eval']["roughness"] * best_ebs['eval']["weights"]["roughness"]))

                print("hole_count {} * weight {} = temp1 {}".format(
                    best_ebs['eval']["hole_count"], best_ebs['eval']["weights"]["hole_count"],
                    best_ebs['eval']["hole_count"] * best_ebs['eval']["weights"]["hole_count"]))

                print("rows_cleared {} * weight {} = temp1 {}".format(
                    best_ebs['eval']["rows_cleared"], best_ebs['eval']["weights"]["rows_cleared"],
                    best_ebs['eval']["rows_cleared"] * best_ebs['eval']["weights"]["rows_cleared"]))

                print("row_transition {} * weight {} = temp1 {}".format(
                    best_ebs['eval']["row_transition"], best_ebs['eval']["weights"]["row_transition"],
                    best_ebs['eval']["row_transition"] * best_ebs['eval']["weights"]["row_transition"]))

                print("col_transition {} * weight {} = temp1 {}".format(
                    best_ebs['eval']["col_transition"], best_ebs['eval']["weights"]["col_transition"],
                    best_ebs['eval']["col_transition"] * best_ebs['eval']["weights"]["col_transition"]))

                print("deepest_well {} * weight {} = temp1 {}".format(
                    best_ebs['eval']["deepest_well"], best_ebs['eval']["weights"]["deepest_well"],
                    best_ebs['eval']["deepest_well"] * best_ebs['eval']["weights"]["deepest_well"]))

                print("total score sum = {}".format(
                    best_ebs['eval']["eval_score"]))
                '''

            else:
                AI.tetris_app.move_rotation_drop(0, 0)

        if AI.tetris_app.game_over:
            AI.tetris_app.print_both()
