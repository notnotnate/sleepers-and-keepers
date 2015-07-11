require 'spec_helper'

feature 'League creator' do
  before do
    @creator = create(:user)
    sign_in @creator
  end

  scenario 'can generate draft picks when the league is full' do
    league = create(:football_league, user: @creator)
    navigate_to_league
    expect(page).to have_no_link 'Set draft order'

    fill_league league
    visit current_path

    click_link 'Set draft order'
    click_button 'Generate draft picks'
    expect(league_on_page).to have_empty_draft_results
  end

  scenario 'can set draft order' do
    league = create(:football_league, user: @creator)
    create(:team, league: league)
    11.times do
      owner = create(:user)
      create(:team, league: league, user: owner)
    end

    navigate_to_league
    click_link 'Set draft order'

    fill_in 'teams[1][draft_pick]', with: 10
    fill_in 'teams[3][draft_pick]', with: 12
    click_button 'Save'

    expect(page).to have_revised_draft_order
  end

  scenario 'can associate keepers with teams after picks are generated', js: true do
    league = create(:football_league, user: @creator)
    fill_league league
    create_player_pool
    navigate_to_league
    expect(page).to have_no_link 'Set keepers'

    click_link 'Set draft order'
    click_button 'Generate draft picks'

    click_link 'League Home'
    click_link 'Set keepers'

    first_team = Team.first
    first_qb = Player.where(position: 'QB').first
    first_qb_name = "#{first_qb.last_name}, #{first_qb.first_name}"

    expect(page).to have_select('team-select', selected: first_team.name)
    expect(page).to have_select('position-select', selected: 'QB')
    expect(page).to have_select('player-select', selected: first_qb_name)
    expect(page).to have_select('pick-select', selected: 'Rd: 1, Pick: 12 (12 overall)')

    last_team = Team.last
    first_rb = Player.where(position: 'RB').first
    first_rb_name = "#{first_rb.last_name}, #{first_rb.first_name}"
    last_teams_first_pick = 'Rd: 1, Pick: 1 (1 overall)'

    select(last_team.name, from: 'team-select')
    select('RB', from: 'position-select')
    expect(page).to have_select('player-select', selected: first_rb_name)
    expect(page).to have_select('pick-select', selected: last_teams_first_pick)

    click_button 'Save'
    expect(page).to have_css('.keeper', text: "#{first_rb_name} - #{last_teams_first_pick}")

    click_link 'League Home'
    click_link 'View draft order'
    expect(page).to have_css('.player', text: first_rb_name)
  end

  scenario 'can start the draft when the league is full' do
    create(:draft_status, description: 'In Progress')
    league = create(:football_league, user: @creator)

    navigate_to_league
    expect(page).to have_no_link 'Start draft'
    fill_league league

    visit current_path
    click_link 'Start draft'
    expect(page).to have_content 'Fantasy Sports Dojo Draft'
  end

  scenario 'can join a draft in progress' do
    create(:football_league, :with_draft_in_progress, user: @creator)

    navigate_to_league
    expect(page).to have_link 'Join draft'
  end

  scenario 'cannot start or join a completed draft' do
    create(:football_league, :with_draft_complete, user: @creator)

    navigate_to_league
    expect(page).to have_no_link 'Start draft'
    expect(page).to have_no_link 'Join draft'
  end
end

feature 'League member' do
  scenario 'cannot do admin actions' do
    league = create(:football_league)
    league_member = create(:user)
    create(:team, league: league, user: league_member)
    sign_in league_member

    navigate_to_league
    expect(page).to have_no_link 'Set draft order'
    expect(page).to have_no_link 'Set keepers'
    expect(page).to have_no_link 'Start draft'
  end
end

def has_revised_draft_order?
  team_one_pick = find('input#team-1')
  team_three_pick = find('input#team-3')

  teams_have_correct_draft_picks_set =
    team_one_pick.value == '10' &&
    team_three_pick.value == '12'

  draft_order_inputs = all('#draft-order input')
  teams_in_correct_order =
    draft_order_inputs[9] == team_one_pick &&
    draft_order_inputs[11] == team_three_pick

  teams_have_correct_draft_picks_set && teams_in_correct_order
end

def league_on_page
  @league_on_page ||= Pages::League.new
end
