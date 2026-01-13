module MatchPredictor
    using CSV,DataFrames
    using MLJ
    using Dates

    function main()

        # Initialization and data cleaning
        games = CSV.read("data/games.csv",DataFrame)
        games = games[:,[:GAME_DATE_EST,:SEASON, :HOME_TEAM_ID,:VISITOR_TEAM_ID,:PTS_home, :PTS_away]]
        subset!(games,:SEASON => ByRow(x -> x == 2021))
        select!(games,Not(:SEASON))
        reverse!(games)

        teams = CSV.read("data/teams.csv",DataFrame)
        teams = teams[:,[:TEAM_ID, :ABBREVIATION]]

        # NBA Team Arena Coordinates (2021 season)
        team_coords = Dict(
            1610612737 => (33.7573, -84.3963),   # Atlanta Hawks - State Farm Arena
            1610612738 => (42.3663, -71.0622),   # Boston Celtics - TD Garden
            1610612751 => (40.6826, -73.9747),   # Brooklyn Nets - Barclays Center
            1610612766 => (35.2251, -80.8392),   # Charlotte Hornets - Spectrum Center
            1610612741 => (41.8807, -87.6742),   # Chicago Bulls - United Center
            1610612739 => (41.4965, -81.6882),   # Cleveland Cavaliers - Rocket Mortgage FieldHouse
            1610612742 => (32.7905, -96.8103),   # Dallas Mavericks - American Airlines Center
            1610612743 => (39.7487, -105.0077),  # Denver Nuggets - Ball Arena
            1610612765 => (42.6960, -83.2456),   # Detroit Pistons - Little Caesars Arena
            1610612744 => (37.7680, -122.3875),  # Golden State Warriors - Chase Center
            1610612745 => (29.7508, -95.3621),   # Houston Rockets - Toyota Center
            1610612754 => (39.7640, -86.1555),   # Indiana Pacers - Gainbridge Fieldhouse
            1610612746 => (34.0430, -118.2673),  # LA Clippers - Crypto.com Arena (formerly Staples)
            1610612747 => (34.0430, -118.2673),  # LA Lakers - Crypto.com Arena (formerly Staples)
            1610612763 => (35.1382, -90.0506),   # Memphis Grizzlies - FedExForum
            1610612748 => (25.7814, -80.1870),   # Miami Heat - FTX Arena (now Kaseya Center)
            1610612749 => (43.0438, -87.9172),   # Milwaukee Bucks - Fiserv Forum
            1610612750 => (44.9795, -93.2761),   # Minnesota Timberwolves - Target Center
            1610612740 => (29.9489, -90.0819),   # New Orleans Pelicans - Smoothie King Center
            1610612752 => (40.7505, -73.9934),   # New York Knicks - Madison Square Garden
            1610612760 => (35.4634, -97.5151),   # Oklahoma City Thunder - Paycom Center
            1610612753 => (28.5392, -81.3839),   # Orlando Magic - Amway Center
            1610612755 => (39.9012, -75.1720),   # Philadelphia 76ers - Wells Fargo Center
            1610612756 => (33.4457, -112.0712),  # Phoenix Suns - Footprint Center
            1610612757 => (45.5316, -122.6668),  # Portland Trail Blazers - Moda Center
            1610612758 => (38.5803, -121.4999),  # Sacramento Kings - Golden 1 Center
            1610612759 => (29.4269, -98.4375),   # San Antonio Spurs - AT&T Center
            1610612761 => (43.6433, -79.3792),   # Toronto Raptors - Scotiabank Arena
            1610612762 => (40.7683, -111.9011),  # Utah Jazz - Vivint Arena
            1610612764 => (38.8983, -77.0209)    # Washington Wizards - Capital One Arena
        )

        # Generating necessary features for the classification
        n_games = nrow(games)
        X = DataFrame(
            A_games_home = zeros(n_games),
            A_games_away = zeros(n_games),
            A_rest_days  = zeros(n_games),
            A_total_trip = zeros(n_games),
            A_b2b = zeros(n_games),
            A_consecutive_home = zeros(n_games),
            A_time_since_last_match = zeros(n_games),
            B_games_home = zeros(n_games),
            B_games_away = zeros(n_games),
            B_rest_days  = zeros(n_games),
            B_total_trip = zeros(n_games),
            B_current_trip = zeros(n_games),
            B_b2b = zeros(n_games),
            B_consecutive_away = zeros(n_games),
            B_time_since_last_match = zeros(n_games)
        )

        for i in 1:n_games
            current_date = games[i, :GAME_DATE_EST]
            home_team = games[i, :HOME_TEAM_ID]
            away_team = games[i, :VISITOR_TEAM_ID]

            home_history = filter(row->
                                (row.HOME_TEAM_ID == home_team || row.VISITOR_TEAM_ID == home_team)&&
                                row.GAME_DATE_EST < current_date&&
                                row.GAME_DATE_EST >= current_date - Day(14), games[1:i-1])
            home_total = nrow(home_history)
            away_history = filter(row->
                                (row.HOME_TEAM_ID == away_team || row.VISITOR_TEAM_ID == away_team)&&
                                row.GAME_DATE_EST < current_date&&
                                row.GAME_DATE_EST >= current_date - Day(14), games[1:i-1])
            X[i, :] = (
                    nrow(filter(row-> row.HOME_TEAM_ID == home_team,home_history)),
                    nrow(filter(row-> row.AWAY_TEAM_ID == home_team,home_history)),
                    14 - nrow(home_history),
                    calculate_total_trip,
                    (home_history[end].GAME_DATE_EST == current_date - Day(1)),
                    count_consecutive_home_games(home_history,home_id),
                    current_date - home_history[end],
                    nrow(filter(row-> row.HOME_TEAM_ID == away_team,away_history)),
                    nrow(filter(row-> row.AWAY_TEAM_ID == away_team,away_history)),
                    14 - nrow(away_history),
                    calculate_total_trip,
                    calculate_current_trip,
                    (away_history[end].GAME_DATE_EST == current_date - Day(1)),
                    count_consecutive_away_games(away_history,away_id),
                    current_date - away_history[end],

                        )


        end



        

    end
end 