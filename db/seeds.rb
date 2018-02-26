# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Signature.create([{:name => "Arquitectura de Computadoras"}, {:name => "Programacion de Maquinas"}])
Role.create([ {name: "Admin"}, {name: "Profesor"}])
User.create([{:email => "admin@matcom.uh.cu", :password => "admin123", :password_confirmation => "admin123", :role_id => 1}, {:email => "hd@matcom.uh.cu", :password => "123456", :password_confirmation => "123456", :role_id => 2 }])