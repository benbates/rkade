class Result < ActiveRecord::Base
  attr_accessible :game_id, :player_id, :score, :winner, :opponent_id, :game_type_id
  
	belongs_to :game	
	belongs_to :player

  before_save :default_values, :order_ladder

  after_save :update_counter_cache
  after_destroy :update_counter_cache
      
  def order_ladder
    if self.winner == true
      distance = 0
      ladder_count = opponent.ladder_pos
      while distance < 2
        potential = Player.where(:ladder_pos => ladder_count += 1).first
        puts "In the first loop"
        if potential.retired != true
          puts "In the second loop"
          if potential == self.player
            puts "In the third loop"
            puts self.id
            puts "1 #{self.player.name}"
            new_pos = opponent.ladder_pos
            puts "New Position = #{new_pos}"
            old_pos = self.player.ladder_pos
            puts "Old Position = #{old_pos}"
            self.player.ladder_pos = new_pos
            opponent.ladder_pos = old_pos
            self.player.ladder_stat = "up"
            opponent.ladder_stat = "down"
            self.player.save
            opponent.save
            swap = true
          end
          distance += 1
        end
      end
      if !swap
      distance = 0
      ladder_count = opponent.ladder_pos
        while distance < 2 && ladder_count != 0
          puts "Ladder Count = #{ladder_count}"
          potential = Player.where(:ladder_pos => ladder_count).first        
          if potential.retired != true
            if potential == self.player
              puts self.id
              puts "2 #{self.player.name}"
              self.player.ladder_stat = "defend"
              opponent.ladder_stat = "deny"
              self.player.save
              opponent.save
            end
            distance += 1
            ladder_count -= 1
          end   
        end
      end
    end
  end  
  
  def default_values
    self.score ||= 0
  end

  def update_counter_cache
    puts "hello"
    self.player.win_count = Result.count(:conditions => ["winner = ? AND player_id = ?", true, self.player.id])
    self.player.points_for = self.player.results.sum(:score)
    if self.player.games.count > 0
      self.player.win_percent = self.player.win_count.to_f/(self.player.results.count(:conditions => {:winner => false}) + player.win_count)
    else
      self.player.win_percent = 0.00
    end
    self.player.save
  end

  def opponent
    opp = Player.find(self.opponent_id)
  end

  def upper_distance

  end

  def lower_distance

  end
  
end


#     if self.player.ladder_pos.between?(opponent.ladder_pos, opponent.ladder_pos + 2)
#       puts self.id
#       puts "1 #{self.player.name}"
#       new_pos = opp.ladder_pos
#       old_pos = self.player.ladder_pos
#       self.player.ladder_pos = new_pos
#       opp.ladder_pos = old_pos
#       self.player.ladder_stat = "up"
#       opp.ladder_stat = "down"
#       self.player.save
#       opp.save
#     else
#         if (self.player.ladder_pos == opponent.ladder_pos-2 || self.player.ladder_pos == opponent.ladder_pos-1)
#         puts self.id
#         puts "2 #{self.player.name}"
#         self.player.ladder_stat = "defend"
#         opp.ladder_stat = "deny"
#           self.player.save
#           opp.save
#         end
#       end
