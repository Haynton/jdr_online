# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#


# ==========================================
# Clean database before seeding
# ==========================================

# Delete existing records in dependency order
Participation.destroy_all
GameTable.destroy_all
User.destroy_all


# ==========================================
# Users
# ==========================================

users = User.create!([
  {
    email: "test@test.com",
    password: "azertyuiopqsdfghjklm",
    username: "othna",
    locale: "fr"
  },
  {
    email: "user@example.com",
    password: "password1234",
    username: "Luara",
    locale: "en"
  }
])


# ==========================================
# Game Tables
# ==========================================

game_tables = GameTable.create!([
  {
    name: "Les Royaumes Oubliés",
    description: "Un monde ancien où les royaumes humains tentent de survivre face aux créatures des ténèbres. D'anciennes ruines renferment des secrets capables de bouleverser l'équilibre du monde.",
    status: "draft",
    creation_step: 1
  },
  {
    name: "L'Ombre du Dragon",
    description: "Depuis le réveil d'un dragon ancestral, les terres sont plongées dans le chaos. Les villages brûlent, les armées se préparent et une ancienne prophétie annonce le retour d'un héros oublié.",
    status: "draft",
    creation_step: 1
  },
  {
    name: "Les Terres de Valdoria",
    description: "Un vaste continent composé de royaumes rivaux, de forêts enchantées et de montagnes mystérieuses. Les aventuriers devront naviguer entre intrigues politiques, magie ancienne et dangers oubliés.",
    status: "draft",
    creation_step: 1
  },
  {
    name: "Le Crépuscule des Elfes",
    description: "Les derniers royaumes elfiques disparaissent peu à peu sous l'influence d'une magie corrompue. Au cœur des forêts millénaires, une force inconnue menace de dévorer toute forme de vie.",
    status: "draft",
    creation_step: 1
  },
  {
    name: "La Couronne des Cendres",
    description: "Après la chute d'un empire puissant, plusieurs seigneurs se disputent les vestiges du trône. Mercenaires, chevaliers et sorciers cherchent à imposer leur propre vision du futur.",
    status: "draft",
    creation_step: 1
  },
  {
    name: "Les Chroniques d'Aetheria",
    description: "Un monde où la magie imprègne chaque pierre et chaque être vivant. Des cités flottantes aux temples oubliés, les aventuriers découvriront les traces d'une civilisation disparue.",
    status: "draft",
    creation_step: 1
  },
  {
    name: "Le Royaume des Brumes",
    description: "Une région mystérieuse recouverte d'une brume éternelle. Les voyageurs racontent que des villages entiers disparaissent et que des créatures anciennes rôdent dans les marécages.",
    status: "draft",
    creation_step: 1
  },
  {
    name: "Les Légendes de Drakemoor",
    description: "Dans les terres sauvages de Drakemoor, les dragons sont considérés comme des dieux vivants. Les clans humains, nains et orcs doivent s'unir face à une menace venue des profondeurs.",
    status: "draft",
    creation_step: 1
  },
  {
    name: "L'Éveil du Néant",
    description: "Une mystérieuse énergie noire commence à corrompre les terres et à transformer les êtres vivants. Les anciens grimoires évoquent une entité bannie depuis des millénaires qui chercherait à revenir.",
    status: "draft",
    creation_step: 1
  },
  {
    name: "Les Marches du Nord",
    description: "Aux frontières du monde connu, de petites forteresses protègent les dernières terres civilisées. Au-delà des montagnes glacées, des tribus barbares et des monstres légendaires se rassemblent.",
    status: "draft",
    creation_step: 1
  }
])


# ==========================================
# Participations
# ==========================================

# Assign the first 5 game tables to Othna
game_tables.first(5).each do |game_table|
  Participation.create!(
    user: users[0],
    game_table: game_table,
    role: "game_master"
  )
end

# Assign the last 5 game tables to Luara
game_tables.last(5).each do |game_table|
  Participation.create!(
    user: users[1],
    game_table: game_table,
    role: "game_master"
  )
end


# ==========================================
# Seeds completed
# ==========================================

puts "Seeds completed:"
puts "- #{User.count} users created"
puts "- #{GameTable.count} game tables created"
puts "- #{Participation.count} participations created"
