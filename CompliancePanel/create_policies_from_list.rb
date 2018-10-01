=begin 
		create_policies_from_list.rb v1.0

		Written by Christopher Kemp for Accenture, with invaluable assistance from Chris Lasell at Pixar.
		This script uses ruby-jss to create Policies in your Jamf Pro server, derived from a plain text 
		list of names (app titles or compliance data points, e.g. "FileVault Encryption" are recommended). 
		
		Three policies will be created for each name: GREEN, RED, and YELLOW. They will be set up as Jamf 
		Self Service policies - you'll need to fill in the ID number of each of your associated icons. 
		Button Text is set for each group, but only the initial button is supported by ruby-jss - this means
		that the "Reinstall" button text will have to be updated manually, along with various other details.
=end

require 'ruby-jss'

# Set the name of the Policy Category to be assigned - this policy must exist on Jamf Server!
pol_cat= "" # Fill in the Blank!

# Set icon ID numbers here:
red_icon = # Fill in the Blank!
yel_icon = # Fill in the Blank!
grn_icon = # Fill in the Blank!

# Server connection details
your_server = "" # Fill in the Blank!
your_user		= "" # Fill in the Blank!
your_pass		= "" # Fill in the Blank!

##### Do not edit below this line, unless you're sure of what you're doing... #####
		
# Connect to the server
JSS::API.connect server: your_server, port: 443, timeout: 600, use_ssl: true, user: your_user, pw: your_pass
# Get the list of computer names to populate the group
print "Location of Policy List for creation: "
pol_list = gets.strip

puts pol_list

# Read in text file 
File.open(pol_list).each do |list|
   
# create GREEN policy	
green_pol = "#{list.strip} - GREEN"
pol = JSS::Policy.make name: green_pol
pol.enabled = false
pol.frequency = :ongoing
pol.category = "#{pol_cat}"
pol.add_to_self_service
pol.self_service_install_button_text = 'OK'
pol.icon = grn_icon
pol.save

# create YELLOW policy
yellow_pol = "#{list.strip} - YELLOW"
pol = JSS::Policy.make name: yellow_pol
pol.enabled = false
pol.frequency = :ongoing
pol.category = "#{pol_cat}"
pol.add_to_self_service
pol.self_service_install_button_text = 'TBD'
pol.icon = yel_icon
pol.save


# create RED policy 
red_pol = "#{list.strip} - RED"
pol = JSS::Policy.make name: red_pol
pol.enabled = false
pol.frequency = :ongoing
pol.category = "#{pol_cat}"
pol.add_to_self_service
pol.self_service_install_button_text = 'FIX'
pol.icon = red_icon
pol.save

end
