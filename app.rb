# frozen_string_literal: true

require "sinatra/base"
require "kramdown"
require "kramdown-parser-gfm"
require "rouge"
require "date"
require_relative "lib/models"
require_relative "lib/runner"
require_relative "lib/sm2"

# Rouge formatter for kramdown that emits <pre><code> without the deprecated HTMLLegacy wrapper.
class CodeFormatter < Rouge::Formatters::HTML
  def initialize(_opts = {}) = super()

  def stream(tokens, &block)
    yield '<pre class="highlight"><code>'
    super
    yield "</code></pre>\n"
  end
end

class App < Sinatra::Base
  set :root, __dir__
  set :bind, "127.0.0.1"
  set :show_exceptions, :after_handler

  FILTER_KEYS = %w[language topic kind difficulty q].freeze
  INTERVIEW_KEYS = %w[ids i r t].freeze
  PER_PAGE = 50

  helpers do
    def h(s) = Rack::Utils.escape_html(s.to_s)

    def md(text)
      return "" if text.nil? || text.empty?
      Kramdown::Document.new(text, input: "GFM", hard_wrap: false,
                             syntax_highlighter: "rouge", syntax_highlighter_opts: { formatter: CodeFormatter }).to_html
    end

    def md_inline(text) = md(text).strip.delete_prefix("<p>").delete_suffix("</p>")

    def rouge_css = (@@rouge_css ||= Rouge::Themes::Github.render(scope: ".highlight"))

    def qs(hash) = Rack::Utils.build_query(hash.reject { |_, v| v.nil? || v.to_s.empty? })
    def filter = FILTER_KEYS.to_h { |k| [k, params[k]] }.reject { |_, v| v.to_s.empty? }
    def interview? = !params[:ids].to_s.empty?
    def interview_params = INTERVIEW_KEYS.to_h { |k| [k, params[k]] }.reject { |_, v| v.to_s.empty? }
    def reveal? = params[:reveal] == "1"
    def item_url(item, extra = {}) = "/items/#{item.id}?#{qs(filter.merge(interview_params).merge(extra))}"

    def hidden_fields
      filter.merge(interview_params).map { |k, v| %(<input type="hidden" name="#{h k}" value="#{h v}">) }.join
    end

    # After an item: next interview step (recording the result char) or next study item for the filter.
    def next_url(result_char = "s")
      if interview?
        "/interview/#{@item.language}?" + qs(ids: params[:ids], i: params[:i].to_i + 1,
                                              r: params[:r].to_s + result_char, t: params[:t])
      else
        "/study?" + qs(filter.merge("after" => @item.id))
      end
    end

    def result_char = @result ? (@result[:correct] ? "1" : "0") : "s"

    def pct(num, den) = den.zero? ? 0 : (100.0 * num / den).round
    def source_link(src) = src.to_s.start_with?("http") ? %(<a href="#{h src}" target="_blank" rel="noopener">#{h src}</a>) : h(src)
  end

  # ---------- dashboard ----------
  get "/" do
    @title = "Dashboard"
    @stats = LANGUAGES.to_h { |l| [l, language_stats(l)] }
    @daily = DB.fetch("SELECT created_at::date AS day, count(*) AS n FROM attempts " \
                      "WHERE created_at >= current_date - 29 GROUP BY 1 ORDER BY 1").to_hash(:day, :n)
    @streak = streak(DB[:attempts].distinct.select_map(Sequel.cast(:created_at, Date)))
    erb :dashboard
  end

  # ---------- browse ----------
  get "/items" do
    @title = "Browse"
    page = [params[:page].to_i, 1].max
    ds = Item.filtered(filter).order(:language, :topic, :difficulty, :title)
    @total = ds.count
    @items = ds.limit(PER_PAGE, (page - 1) * PER_PAGE).all
    @page = page
    @pages = (@total / PER_PAGE.to_f).ceil
    @last = DB[:attempts].where(item_id: @items.map(&:id)).order(:item_id, Sequel.desc(:created_at))
                         .distinct(:item_id).to_hash(:item_id, :correct)
    @topics = Item.distinct.select_order_map(%i[language topic])
    erb :items
  end

  get "/study" do
    item = Item.next_for(filter, exclude_id: params[:after])
    redirect(item ? item_url(item) : "/items?#{qs(filter.merge('empty' => 1))}")
  end

  # ---------- item ----------
  get "/items/:id" do
    @item = Item[params[:id]] || halt(404, "No such item")
    @title = @item.title
    erb :item
  end

  post "/items/:id/attempt" do
    @item = Item[params[:id]] || halt(404, "No such item")
    @title = @item.title
    if @item.mcq? && params[:choice]
      choice = params[:choice].to_i
      correct = choice == @item.correct_choice
      @result = { correct: correct, choice: choice }
      record_attempt(@item, correct: correct, response: choice.to_s, grade: correct ? "good" : "again")
    elsif @item.self_graded? && SM2::GRADES.key?(params[:grade])
      grade = params[:grade]
      correct = %w[good easy].include?(grade)
      @result = { correct: correct, grade: grade }
      record_attempt(@item, correct: correct, response: grade, grade: grade)
    elsif @item.code? && params[:code]
      res = Runner.run(@item.language, params[:code], @item.tests)
      @result = { correct: res.ok, output: res.output, code: params[:code] }
      record_attempt(@item, correct: res.ok, response: params[:code], grade: res.ok ? "good" : "again")
    else
      halt 400, "Bad attempt"
    end
    erb :item
  end

  # ---------- mock interview ----------
  get "/interview/:language" do
    lang = params[:language]
    halt 404, "Unknown language" unless LANGUAGES.include?(lang)
    if params[:ids].to_s.empty?
      ids = Item.pick_interview(lang, (params[:n] || 10).to_i)
      halt 404, "No #{lang} items seeded yet" if ids.empty?
      redirect "/interview/#{lang}?#{qs(ids: ids.join('-'), i: 0, t: Time.now.to_i)}"
    end
    ids = params[:ids].split("-").map(&:to_i)
    i = params[:i].to_i
    redirect "/items/#{ids[i]}?#{qs(interview_params)}" if i < ids.size

    @title = "Interview summary"
    @results = params[:r].to_s.chars
    by_id = Item.where(id: ids).to_hash(:id)
    @items = ids.filter_map { by_id[_1] }
    @elapsed = Time.now.to_i - params[:t].to_i
    erb :interview_summary
  end

  not_found { erb "<h1>404</h1><p>#{h(body.join)}</p>" }

  private

  def language_stats(lang)
    topics = DB.fetch(<<~SQL, lang).all
      SELECT i.topic,
             count(DISTINCT i.id)                    AS items,
             count(DISTINCT a.item_id)               AS attempted,
             count(a.id)                             AS attempts,
             count(a.id) FILTER (WHERE a.correct)    AS correct
      FROM items i LEFT JOIN attempts a ON a.item_id = i.id
      WHERE i.language = ?
      GROUP BY i.topic ORDER BY i.topic
    SQL
    topics.each { |t| t[:accuracy] = pct(t[:correct], t[:attempts]); t[:weak] = t[:attempts] >= 3 && t[:accuracy] < 60 }
    sum = ->(k) { topics.sum { _1[k] } }
    {
      total: sum[:items], attempted: sum[:attempted], attempts: sum[:attempts],
      accuracy: pct(sum[:correct], sum[:attempts]),
      due: DB[:reviews].join(:items, id: :item_id).where(language: lang).where { due_on <= Date.today }.count,
      topics: topics
    }
  end

  # Consecutive days with activity ending today (or yesterday, if today has none yet).
  def streak(days)
    set = days.to_set
    day = set.include?(Date.today) ? Date.today : Date.today - 1
    n = 0
    while set.include?(day)
      n += 1
      day -= 1
    end
    n
  end
end
