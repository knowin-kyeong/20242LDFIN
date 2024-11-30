from random import randrange as rand

import numpy as np
from colorama import Fore, Style

import copy, numpy

# Copyright (c) 2010 "Kevin Chabowski"<kevin@kch42.de>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Author: Kevin Chabowski
# Modified bu Juwon Seo (knowin-kyeong)

# color mapping
COLOR_MAP = {
    0: Fore.WHITE,
    1: Fore.BLUE,
    2: Fore.CYAN,
    3: Fore.YELLOW,
    4: Fore.GREEN,
    5: Fore.LIGHTYELLOW_EX,
    6: Fore.MAGENTA,
    7: Fore.RED,
    9: Fore.BLACK
}

# The configuration
config = {
    'cols': 10,
    'rows': 20,
}

# Define the shapes of the single parts
tetris_shapes = [
    [[1, 1, 1, 1]],

    [[2, 2],
     [2, 2]],

    [[3, 0, 0],
     [3, 3, 3]],

    [[0, 4, 4],
     [4, 4, 0]],

    [[0, 0, 5],
     [5, 5, 5]],

    [[0, 6, 0],
     [6, 6, 6]],

    [[7, 7, 0],
     [0, 7, 7]]
]


def colorize_row(row):
    return ''.join(COLOR_MAP.get(num, Fore.RESET) + str(num) + Style.RESET_ALL for num in row)


def rotate_clockwise(shape):
    return [[shape[y][x] for y in range(len(shape))] for x in range(len(shape[0]) - 1, -1, -1)]


def check_collision(board, shape, offset):
    off_x, off_y = offset
    for cy, row in enumerate(shape):
        for cx, cell in enumerate(row):
            if cell != 0 and board[cy + off_y][cx + off_x] != 0 and cy + off_y >= 4:
                return True
    return False


def remove_row(board, row):
    board = np.delete(board, row, axis=0)
    board = np.insert(board, 4, [0 for i in range(config['cols'])], axis=0)
    return board


def join_matrixes(mat1, mat2, mat2_off):
    mat3 = copy.deepcopy(mat1)
    off_x, off_y = mat2_off

    assert (0 <= len(mat2) + off_y - 1 < config['rows'] + 4)
    assert (0 <= len(mat2[0]) + off_x - 1 < config['cols'])

    for cy in range(len(mat2)):
        for cx in range(len(mat2[0])):
            if 0 <= cy + off_y < config['rows'] + 4 and 0 <= cx + off_x < config['cols']:
                val = mat2[cy][cx]
                if val != 0:
                    mat3[cy + off_y][cx + off_x] = val
    return mat3


def new_board():
    board = [[9 for x in range(config['cols'])] for y in range(4)]
    board += [[0 for x in range(config['cols'])] for y in range(config['rows'])]
    return board


class TetrisApp(object):
    def __init__(self):
        self.board = new_board()
        self.game_over = False

        self.stone = None
        self.stone_x = None
        self.stone_y = None

        self.needs_actions = True
        self.actions = None

        self.drop_blocks = 0
        self.cleared_lines = 0

    def new_stone(self):
        self.stone = tetris_shapes[rand(len(tetris_shapes))]
        self.stone_x = 0
        self.stone_y = 0

    def set_stone(self, stone):
        self.stone = stone
        self.stone_x = 0
        self.stone_y = 0

    def get_stone(self):
        if self.stone is None:
            return None
        else:
            return self.stone, self.stone_x, self.stone_y

    def set_board(self, board):
        self.board = board

    def get_board(self):
        if self.board is None:
            return None
        else:
            return self.board

    def print_board(self):
        for idx, row in enumerate(self.board):
            if idx >= 5:
                print("{:<3} [{}]".format(idx - 4, colorize_row(row)))
            else:
                print("{:<3} [{}]".format(idx - 4, colorize_row(row)), end="    ")
                if idx == 4:
                    print("<Next>")
                elif idx >= 4 - len(self.stone):
                    print("[{}]".format(colorize_row(self.stone[idx - (4 - len(self.stone))])))
                else:
                    print("")

        print("idx [9876543210]")
        print("Score: {}".format(self.get_score()))
        print("Clear Lines: {}".format(self.cleared_lines))
        print("Dropped Blockes: {}".format(self.drop_blocks))

    def print_both(self):

        for idx, row in enumerate(self.board):
            print("{:<3} [{}]".format(idx - 4, colorize_row(row)))

        print("idx [9876543210]")
        print("Score: {}".format(self.get_score()))
        print("Clear Lines: {}".format(self.cleared_lines))
        print("Dropped Blockes: {}".format(self.drop_blocks))

    def move(self, col):
        effective_width = 0

        for x in range(len(self.stone[0])):
            all_zero = True
            for y in range(len(self.stone)):
                if self.stone[y][x] != 0:
                    all_zero = False
                    break

            if all_zero and effective_width != 0:
                break
            elif not all_zero:
                effective_width += 1

        if col < 0 or col + effective_width > config['cols']:
            return -1
        elif check_collision(self.board, self.stone, (col, self.stone_y)):
            return -1
        else:
            self.stone_x = col
            return 0

    def drop(self):
        while self.stone_y + len(self.stone) <= len(self.board) \
                and not check_collision(self.board, self.stone, (self.stone_x, self.stone_y)):
            self.stone_y += 1
        self.stone_y -= 1

        self.board = join_matrixes(self.board, self.stone, (self.stone_x, self.stone_y))

        changed = True
        while changed:
            changed = False
            for i, row in enumerate(self.board):
                if 0 not in row and 9 not in row:
                    self.board = remove_row(self.board, i)
                    self.cleared_lines += 1
                    changed = True
                    break

        for idx, row in enumerate(self.board):
            if idx >= 4:
                break
            else:
                for x in row:
                    if x != 9:
                        self.game_over = True
                        break

        if not self.game_over:
            self.drop_blocks += 1

    def rotate_stone(self):
        new_stone = rotate_clockwise(self.stone)
        if not check_collision(self.board, new_stone, (self.stone_x, self.stone_y)):
            self.stone = new_stone

    def move_rotation_drop(self, col, rot):
        if rot < 0 or rot >= 4:
            return -1

        for i in range(rot):
            self.rotate_stone()

        ret = self.move(col)
        if ret == -1:
            for i in range(4 - rot):
                self.rotate_stone()
            return -1

        self.drop()
        return 0

    def get_score(self):
        return self.drop_blocks + 10 * self.cleared_lines

    def get_state(self):
        return {"board": numpy.copy(self.board),
                "stone": numpy.copy(self.stone),
                "score": self.get_score(),
                "drop_blocks": self.drop_blocks,
                "cleared_lines": self.cleared_lines,
                "game_over": self.game_over,
                "needs_actions": self.needs_actions}

    def reflect_AI_choice(self):
        self.needs_actions = False


if __name__ == '__main__':
    App = TetrisApp()
    while not App.game_over:
        App.new_stone()
        App.print_board()

        if App.needs_actions:
            col, rot = map(int, input('Leftmost idx, Rotation mode = ').split())
            while True:
                ret = App.move_rotation_drop(9 - col, rot)  # convert left: 9(input) -> left: 0(idx)
                if ret == 0:
                    break
                else:
                    print("Invalid Move")
                    App.print_board()
                    col, rot = map(int, input('Leftmost idx, Rotation mode = ').split())
        else:
            input('Press any key to continue')