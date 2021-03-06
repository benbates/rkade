class Result < ActiveRecord::Base
  attr_accessible :game_id, :player_id, :score, :winner, :opponent_id, :game_type_id
  
	belongs_to :game	
	belongs_to :player

  before_save :default_values, :order_ladder

  after_save :update_counter_cache, :update_relationship
  after_destroy :update_counter_cache, :update_relationship
      
  def order_ladder
    if self.winner == true
      opp = Player.find(self.opponent_id)
      if self.player.ladder_pos.between?(opponent.ladder_pos, opponent.ladder_pos + lower_distance)
        new_pos = opp.ladder_pos
        old_pos = self.player.ladder_pos
        self.player.ladder_pos = new_pos
        opp.ladder_pos = old_pos
        self.player.ladder_stat = "up"
        opp.ladder_stat = "down"
        self.player.save
        opp.save
      elsif self.player.ladder_pos.between?(opp.ladder_pos - upper_distance, opp.ladder_pos)  
        self.player.ladder_stat = "defend"
        opp.ladder_stat = "deny"
        self.player.save
        opp.save
      end
    end
  end  
  
  def default_values
    self.score ||= 0
  end

  def update_counter_cache
    self.player.win_count = Result.count(:conditions => ["winner = ? AND player_id = ?", true, self.player.id])
    self.player.loss_count = Result.count(:conditions => ["winner != ? AND player_id = ?", true, self.player.id])    
    self.player.points_for = self.player.results.sum(:score)
    self.player.points_against = Result.sum(:score, :conditions => { :opponent_id => self.player.id })
    if self.player.games.count > 0
      self.player.win_percent = self.player.win_count.to_f/(self.player.loss_count + self.player.win_count)
    else
      self.player.win_percent = 0.00
    end
    self.player.save
    puts "After Result Save"
  end

  def update_relationship

    opponent = Player.find(self.opponent_id)
    total_games = self.player.results.where(:opponent_id => self.opponent_id).count
    win_count =  self.player.results.where(:opponent_id => self.opponent_id,  :winner => true).count
    loss_count = total_games - win_count
    points_for = self.player.results.where(:opponent_id => self.opponent_id).sum(:score)
    points_against = Result.where(:player_id => self.opponent_id, :opponent_id => self.player.id).sum(:score)
    if win_count > 0
      win_percent = (win_count.to_f/(loss_count + win_count))
    else  
      win_percent = 0.000
    end
    if Relationship.where(:player_id => self.player.id, :opponent_id => self.opponent_id).count == 1
      relationship = Relationship.where(:player_id => self.player.id, :opponent_id => opponent_id).first
      relationship.update_attributes :win_count => win_count,
                          :loss_count => loss_count,
                          :points_for => points_for,
                          :points_against => points_against,
                          :win_percent => win_percent
    else
      Relationship.create :player_id => player.id,
                          :opponent_id => opponent.id,
                          :win_count => win_count,
                          :loss_count => loss_count,
                          :points_for => points_for,
                          :points_against => points_against,
                          :win_percent => win_percent
    end
  end

  def opponent
    opp = Player.find(self.opponent_id)
  end

  def upper_distance
      distance = 0
      ladder_count = self.player.ladder_pos
      while distance < 2 && ladder_count < ladder_bottom
        potential = Player.where(:ladder_pos => ladder_count += 1).first
        if potential.is_not_retired
          distance += 1
        end
      end
    ladder_count - self.player.ladder_pos
  end

  def lower_distance
    distance = 0
    ladder_count = self.player.ladder_pos
    while distance < 2 && ladder_count > 1
      potential = Player.where(:ladder_pos => ladder_count -= 1).first
      if potential.is_not_retired
        distance += 1
      end
    end
    self.player.ladder_pos - ladder_count
  end

  def ladder_bottom
    bottom = Player.all(:order => :ladder_pos).last
    bottom.ladder_pos
  end
  
end
