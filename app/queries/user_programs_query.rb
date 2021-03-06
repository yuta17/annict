# frozen_string_literal: true

class UserProgramsQuery
  attr_reader :user

  def initialize(user)
    @user = user
  end

  # 記録していないエピソードと紐づく番組情報を返す
  def unwatched
    Program.where(id: program_ids(channel_works, scope: :unwatched))
  end

  def all
    Program.where(id: program_ids(channel_works, scope: :all))
  end

  private

  def channel_works
    works = user.works.wanna_watch_and_watching
    user.channel_works.where(work: works)
  end

  def program_ids(channel_works, scope: :all)
    program_ids = []

    channel_works.each do |cw|
      episode_ids = case scope
      when :all then cw.work.episodes.published.pluck(:id)
      when :unwatched then user.episodes.unwatched(cw.work).pluck(:id)
      end

      next if episode_ids.blank?

      # 過去の放送を取得しないようにするため、直近の放送分のみ取得する
      sql = <<-SQL
        WITH ranked_programs AS (
          SELECT id, episode_id, started_at,
            dense_rank() OVER (
              PARTITION BY episode_id ORDER BY started_at ASC
            ) AS episode_rank
          FROM programs
          WHERE
            channel_id = #{cw.channel_id} AND
            episode_id IN (#{episode_ids.join(",")})
        )
        SELECT id FROM ranked_programs WHERE
          episode_rank = (SELECT max(episode_rank) FROM ranked_programs);
      SQL
      program_ids << Program.find_by_sql(sql).map(&:id)
    end

    program_ids.flatten
  end
end
