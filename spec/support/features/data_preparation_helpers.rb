module Features
  module DataPreparationHelpers
    def create_player_pool
      FactoryGirl.create(:player, sport: Sport.last)
      FactoryGirl.create(:player, position: 'QB', sport: Sport.last)
      FactoryGirl.create(:player, position: 'WR', sport: Sport.last)
      FactoryGirl.create(:player, position: 'TE', sport: Sport.last)
      FactoryGirl.create(:player, position: 'K', sport: Sport.last)
      FactoryGirl.create(:player, position: 'DST', sport: Sport.last)
    end

    def fill_league(league)
      teams_needed_count = league.size - league.teams.length
      teams_needed_count.times do
        owner = FactoryGirl.create(:user)
        FactoryGirl.create(:team, league: league, user: owner)
      end
    end
  end
end