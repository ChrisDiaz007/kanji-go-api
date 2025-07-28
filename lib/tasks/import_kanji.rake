namespace :import do
  desc "Import kanji data from kanjiapi.dev"
  task kanji: :environment do
    require 'net/http'
    require 'json'

    puts "📦 Fetching full kanji list..."
    url = URI("https://kanjiapi.dev/v1/kanji/all")
    response = Net::HTTP.get(url)
    kanji_list = JSON.parse(response)

    puts "📄 Retrieved #{kanji_list.size} kanji. Importing..."

    kanji_list.each_with_index do |character, index|
      print "⛏️  [#{index + 1}/#{kanji_list.size}] #{character} ... "

      kanji_url = URI("https://kanjiapi.dev/v1/kanji/#{URI.encode_www_form_component(character)}")
      kanji_response = Net::HTTP.get(kanji_url)
      data = JSON.parse(kanji_response)

      Kanji.create_with(
        meanings: data["meanings"],
        onyomi: data["on_readings"],
        kunyomi: data["kun_readings"],
        name_readings: data["name_readings"],
        notes: data["notes"],
        heisig_en: data["heisig_en"],
        stroke_count: data["stroke_count"],
        grade: data["grade"],
        jlpt_level: data["jlpt"],
        freq_mainichi_shinbun: data["freq_mainichi_shinbun"],
        unicode: data["unicode"]
      ).find_or_create_by!(character: character)

      puts "✅"
    end

    puts "🎉 Done! Kanji imported."
  end
end
