# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
load File.expand_path("../bin/check", __dir__)

class CheckTest < Minitest::Test
  MAP_ENTRY = <<~YAML
    city: Paris
    country: FR
    activity: Sunday photography walk
    category: photography
    group_size: 6
    i_would_host: true
    description: >
      A slow walk along the canal, swapping tips, no gear snobbery.
  YAML

  PRINCIPLE = <<~MARKDOWN
    # Everyone can leave

    **Why:** Nobody should stay somewhere they don't feel good.

    **In practice:** You can leave at any time without a reason. The host says so at the start.
  MARKDOWN

  def setup
    @root = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_the_examples_pass
    write "map/fr/paris/sunday-photography-walk.yml", MAP_ENTRY
    write "manifesto/the-best-conversations.md", "The best conversations happen when nobody is looking at a screen.\n"
    write "constitution/everyone-can-leave.md", PRINCIPLE

    assert_equal [], problems
  end

  def test_the_seed_entries_in_this_repo_pass
    assert_equal [], Offline::Check.new(File.expand_path("..", __dir__)).problems
  end

  def test_files_in_the_wrong_place
    write "map/paris/walk.yml", MAP_ENTRY
    write "map/fr/paris/Sunday_Walk.yml", MAP_ENTRY
    write "manifesto/line.txt", "Meet people.\n"
    write "constitution/nested/principle.md", PRINCIPLE

    assert_problems [
      "constitution/nested/principle.md: Principles go in constitution/<name>.md",
      "manifesto/line.txt: Manifesto lines go in manifesto/<name>.md",
      "map/fr/paris/Sunday_Walk.yml: Map entries go in map/<country>/<city>/<name>.yml",
      "map/paris/walk.yml: Map entries go in map/<country>/<city>/<name>.yml"
    ]
  end

  def test_a_changed_file_outside_the_folders
    write "paris.yml", MAP_ENTRY

    assert_problems ["paris.yml: Entries go in map/, manifesto/ or constitution/."], changed: [ "paris.yml" ]
    assert_equal [], problems(changed: [ "README.md", ".github/workflows/check.yml" ])
  end

  def test_only_changed_entries_are_reported
    write "map/fr/paris/old.yml", "not: [valid"
    write "manifesto/new.md", "Meet people.\n"

    assert_equal [], problems(changed: [ "manifesto/new.md" ])
  end

  def test_links_are_refused
    path = File.join(@root, "manifesto/link.md")
    FileUtils.mkdir_p(File.dirname(path))
    File.symlink("/etc/hosts", path)

    assert_problems ["manifesto/link.md: Must be a plain file, not a link."]
  end

  def test_invalid_yaml
    write "map/fr/paris/walk.yml", "city: [Paris\n"

    assert_problems ["map/fr/paris/walk.yml: Isn't valid YAML"]
  end

  def test_yaml_that_isnt_a_list_of_fields
    write "map/fr/paris/walk.yml", "- Paris\n"

    assert_problems ["map/fr/paris/walk.yml: Isn't a list of fields"]
  end

  def test_yaml_aliases_and_dates_are_refused
    write "map/fr/paris/alias.yml", "city: &c Paris\nactivity: *c\n"
    write "map/fr/paris/date.yml", "city: 2026-11-01\n"

    assert_problems ["map/fr/paris/alias.yml: Isn't valid YAML", "map/fr/paris/date.yml: Isn't valid YAML"]
  end

  def test_missing_and_extra_fields
    write "map/fr/paris/walk.yml", MAP_ENTRY.sub(/^group_size.*\n/, "").sub("city: Paris", "city: Paris\nemail_me: yes")

    assert_problems [
      "map/fr/paris/walk.yml: Is missing group_size.",
      "map/fr/paris/walk.yml: Has fields we don't keep: email_me.",
      "map/fr/paris/walk.yml: group_size: a whole number from 2 to 15"
    ]
  end

  def test_each_field
    write "map/fr/paris/walk.yml", <<~YAML
      city: ""
      country: France
      activity: #{"a" * 81}
      category: Photo Walks
      group_size: 40
      i_would_host: maybe
      description: #{"b" * 281}
    YAML

    assert_problems [
      "map/fr/paris/walk.yml: city: a city name",
      "map/fr/paris/walk.yml: country: the two-letter country code",
      "map/fr/paris/walk.yml: activity: what you'd do",
      "map/fr/paris/walk.yml: category: one lowercase word",
      "map/fr/paris/walk.yml: group_size: a whole number from 2 to 15",
      "map/fr/paris/walk.yml: i_would_host: true or false.",
      "map/fr/paris/walk.yml: description: what it's like"
    ]
  end

  def test_folders_follow_the_city_and_country
    write "map/de/lyon/walk.yml", MAP_ENTRY
    write "map/fr/saint-etienne/walk.yml", MAP_ENTRY.sub("Paris", "Saint-Étienne")

    assert_problems [
      "map/de/lyon/walk.yml: city: the folder must be paris/",
      "map/de/lyon/walk.yml: country: the folder must be fr/"
    ]
  end

  def test_no_dating_entries
    write "map/fr/paris/dating.yml", MAP_ENTRY.sub("category: photography", "category: dating")
    write "map/fr/paris/singles.yml", MAP_ENTRY.sub("Sunday photography walk", "Singles walk")

    assert_problems [
      "map/fr/paris/dating.yml: No dating entries",
      "map/fr/paris/singles.yml: No dating entries"
    ]
  end

  def test_no_contact_details
    write "manifesto/email.md", "Write to me at ana@example.com and meet.\n"
    write "manifesto/phone.md", "Call +33 6 12 34 56 78 and meet.\n"
    write "manifesto/url.md", "See https://example.com and meet.\n"
    write "manifesto/www.md", "See www.example.org and meet.\n"
    write "manifesto/domain.md", "See meetups.io and meet.\n"
    write "manifesto/fine.md", "In 2026, groups of 6 met 12 times. St. Martin agrees, e.g. Node.js folks.\n"

    assert_problems [
      "manifesto/domain.md: Has a link.",
      "manifesto/email.md: Has an email address.",
      "manifesto/phone.md: Has a phone number.",
      "manifesto/url.md: Has a link.",
      "manifesto/www.md: Has a link."
    ]
  end

  def test_manifesto_lines
    write "manifesto/empty.md", "\n"
    write "manifesto/two.md", "Meet people.\nPut the phone away.\n"
    write "manifesto/long.md", "#{"a" * 141}\n"

    assert_problems [
      "manifesto/empty.md: Is empty.",
      "manifesto/long.md: Is 141 characters: keep it to 140.",
      "manifesto/two.md: One statement, on one line."
    ]
  end

  def test_constitution_shape_and_length
    write "constitution/shape.md", "Everyone can leave, because nobody should stay.\n"
    write "constitution/long.md", PRINCIPLE.sub("without a reason", "a" * 600)

    assert_problems [
      "constitution/long.md: Is 7",
      "constitution/shape.md: Needs three parts"
    ]
  end

  def test_exact_and_near_duplicates
    write "manifesto/a.md", "The best conversations happen offline.\n"
    write "manifesto/b.md", "The best conversations happen offline!\n"
    write "manifesto/c.md", "The best conversation happens offline.\n"
    write "manifesto/d.md", "Strangers become friends over a shared table.\n"

    assert_problems [
      "manifesto/b.md: Is the same as manifesto/a.md.",
      "manifesto/c.md: Is the same as manifesto/a.md."
    ]
  end

  def test_a_changed_duplicate_names_the_existing_entry
    write "manifesto/z-old.md", "Meet people where they are.\n"
    write "manifesto/a-new.md", "Meet people where they are\n"

    assert_problems ["manifesto/a-new.md: Is the same as manifesto/z-old.md."], changed: [ "manifesto/a-new.md" ]
  end

  def test_map_duplicates_stay_within_a_city
    write "map/fr/paris/walk.yml", MAP_ENTRY
    write "map/fr/paris/walk-again.yml", MAP_ENTRY.sub("Sunday photography walk", "Sunday Photography Walk.")
    write "map/fr/lyon/walk.yml", MAP_ENTRY.sub("Paris", "Lyon")

    assert_problems ["map/fr/paris/walk.yml: Is the same as map/fr/paris/walk-again.yml."]
  end

  def test_principle_duplicates_compare_the_principle
    write "constitution/a.md", PRINCIPLE
    write "constitution/b.md", PRINCIPLE.sub("start.", "beginning.")

    assert_problems ["constitution/b.md: Is the same as constitution/a.md."]
  end

  private
    def write(path, content)
      full = File.join(@root, path)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, content)
    end

    def problems(changed: nil)
      Offline::Check.new(@root, changed: changed).problems.map { |problem| "#{problem.path}: #{problem.message}" }.sort
    end

    def assert_problems(expected, changed: nil)
      actual = problems(changed: changed)
      assert_equal expected.size, actual.size, actual.join("\n")
      expected.sort.zip(actual).each { |prefix, line| assert line.start_with?(prefix), "Expected #{line.inspect} to start with #{prefix.inspect}" }
    end
end
