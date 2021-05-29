# frozen_string_literal: true
require 'colorize'

class Board
  attr_reader :columns, :rows, :board, :possible_columns, :last_move, :current_player, :game_won, :current_message

  POSIBLE_COLUMNS_RANGE = ('A'..'Z').freeze
  TABLE_SEPARATOR = "---------------------------------\n".freeze

  def initialize(columns = 7, rows = 6)
    @columns = columns
    @rows = rows
    @board = {}
    @possible_columns = POSIBLE_COLUMNS_RANGE.first(columns)
    @last_move = nil
    @current_player = :R
    @game_won = false
  end

  def run
    build_board
    run_game
    puts current_message
  end

  def build_board
    possible_columns.each_with_index do |column, index|
      board[index] = build_rows
    end
  end

  def build_rows
    column_rows = (0..(rows - 1)).to_a.inject({}) do |obj, row|
                    obj[row] = nil
                    obj
                  end
    column_rows[:occupied_slots] = 0
    column_rows
  end

  def print_board
    printed_board = ''
    rows.downto(1).each do |row_n|
      printed_board += " #{row_n} |"
      (0..(columns - 1)).each do |col_n|
        printed_board += " #{print_player(board[col_n][row_n - 1]) || "\u00A0"} |"
      end
      printed_board += "\n"
    end
    printed_board += TABLE_SEPARATOR
    printed_board += "   | #{possible_columns.join(" | ")} |"
    puts printed_board
  end

  def print_player(player)
  end

  def run_game
    print_board
    command = get_command
    run_command(command)
    find_winner
    if game_won
      print_board
    else
      switch_player
      run_game
    end
  end

  def find_winner
    return if last_move.nil?

    validate_with(HorizontalValidator)
    validate_with(VerticalValidator)
    validate_with(AcuteAngleValidator)
    validate_with(ObtuseAngleValidator)
  end

  def validate_with(validator)
    return if @game_won

    @game_won = validator.new(self).run
    @current_message = "GAME WON BY #{@current_player}".green if @game_won
  end

  def get_command
    puts "Type a column name:".green
    gets.strip.capitalize
  end

  def run_command(command)
    case command
    when "<"
      if last_move.nil?
        puts "Invalid Move, you can't undo when no movements were made".red
      else
        undo_move
      end
    when *possible_columns
      column_index = possible_columns.index(command)
      populate_slot(column_index)
    else
      puts "Invalid Move, you chose an invalid command or column, try again".red
    end
  end

  def column_full?(column_index)
    board[column_index][:occupied_slots] >= rows
  end

  def populate_slot(column_index)
    if column_full?(column_index)
      puts "Column doesn't have any available slots, please chose another column".red
    else
      row_index = board[column_index][:occupied_slots]
      board[column_index][row_index] = current_player
      board[column_index][:occupied_slots] = row_index + 1
      @last_move = [column_index, row_index]
    end
  end

  def undo_move
    column_index = last_move[0]
    row_index = last_move[1]
    if board[column_index][row_index] == nil
      puts "You already undid your last move".red
    else
      board[column_index][row_index] = nil
      board[column_index][:occupied_slots] = row_index
    end
  end

  def switch_player
    @current_player = current_player == :R ? :B : :R
  end
end

class WinValidator
  attr_reader :board, :column_index, :row_index, :current_player, :found_positions, :board_object

  def initialize(board_object)
    @board_object = board_object
    @current_player = board_object.current_player
    @board = board_object.board
    @column_index = board_object.last_move[0]
    @row_index = board_object.last_move[1]
    @found_positions = 1
  end


  def run
    check_up
    check_down
    found_positions >= 4
  end
end

class HorizontalValidator < WinValidator
  def check_up
    (column_index - 1).downto(column_index - 3).each do |index|
      break if index < 0

      board[index][row_index] == current_player ? @found_positions += 1 : break
    end
  end

  def check_down
    ((column_index + 1)..(column_index + 3)).each do |index|
      break if index > (board_object.columns - 1)

      board[index][row_index] == current_player ? @found_positions += 1 : break
    end
  end
end

class VerticalValidator < WinValidator
  def check_down
    (row_index - 1).downto(row_index - 3).each do |index|
      break if index < 0

      board[column_index][index] == current_player ? @found_positions += 1 : break
    end
  end

  def check_up
    ((row_index + 1)..(row_index + 3)).each do |index|
      break if index > (board_object.rows - 1)

      board[column_index][index] == current_player ? @found_positions += 1 : break
    end
  end
end

class AcuteAngleValidator < WinValidator
  def check_down
    (1..3).each do |step_down|
      r_index = row_index - step_down
      c_index = column_index - step_down
      break if r_index < 0 || c_index < 0

      board[c_index][r_index] == current_player ? @found_positions += 1 : break
    end
  end

  def check_up
    (1..3).each do |step_up|
      r_index = row_index + step_up
      c_index = column_index + step_up
      break if r_index > (board_object.rows - 1) || c_index > (board_object.columns - 1)

      board[c_index][r_index] == current_player ? @found_positions += 1 : break
    end
  end
end

class ObtuseAngleValidator < WinValidator
  def check_down
    (1..3).each do |step_down|
      r_index = row_index - step_down
      c_index = column_index + step_down
      break if r_index < 0 || c_index > (board_object.columns - 1)
      board[c_index][r_index] == current_player ? @found_positions += 1 : break
    end
  end

  def check_up
    (1..3).each do |step_up|
      r_index = row_index + step_up
      c_index = column_index - step_up
      break if r_index > (board_object.rows - 1) || c_index < 0

      board[c_index][r_index] == current_player ? @found_positions += 1 : break
    end
  end
end

Board.new.run