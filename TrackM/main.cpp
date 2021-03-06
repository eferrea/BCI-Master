//
//  main.cpp
// 
//
//  Created by Enrico Ferrea on 15/07/2021.

#include <SFML/Graphics.hpp>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <cmath> 
#include "vrpn_server_class.h"
//using namespace std;

static std::vector<double> temp{ 0, 0, 0, 0, 0 }; //static variable used to retrieve tracker positional values
static std::string message;

void VRPN_CALLBACK handle_tracker(void* userData, const vrpn_TRACKERCB t)
{
	//std::cout << "Tracker '" << t.sensor << "' : " << t.pos[0] << "," << t.pos[1] << "," << t.pos[2] << std::endl;

	std::vector<std::vector<double>> *buff = static_cast<std::vector<std::vector<double>> *>(userData);


	temp.resize(5);
	temp[0] = t.msg_time.tv_sec;
	temp[1] = t.msg_time.tv_usec;
	temp[2] = t.pos[0];
	temp[3] = t.pos[1];
	temp[4] = t.pos[2];


}

void VRPN_CALLBACK handle_message(void *userData, const vrpn_TEXTCB info)
{


	std::cout << "message received %s\n" << info.message << std::endl;
	message = info.message;

}




int main()
{
	//Read data from configuration file
	std::ifstream fin("config.txt");
	std::string line,client_address,server_address, tracker_name,bci_name;
	//port can be adjusted but is not necsssary
	int port = 0000;
	//adjust screen resolution for pixel to mm conversion
	double dpi = 108.79;
	while (getline(fin, line)) {
		std::istringstream sin(line.substr(line.find("=") + 1));
		if (line.find("IP_address_server") != -1)
			sin >> server_address;
		else if (line.find("IP_address_client") != -1)
			sin >> client_address;
		else if (line.find("port") != -1)
			sin >> port;
		else if (line.find("dpi") != -1)
			sin >> dpi;
	}

	std::cout << "IP_server: " << server_address << '\n';
	std::cout << "IP_client: " << client_address << '\n';
	std::cout << "Port: " << port<< '\n';
	std::cout << "dpi screen: " << dpi << '\n';
	

	

	//initialize vrpn client variables.!!! change the address to match with ip address of computer running BCI framework
	vrpn_Tracker_Remote* vrpnTracker = new vrpn_Tracker_Remote(client_address.c_str());
	vrpn_Text_Receiver* vrpnText = new vrpn_Text_Receiver(client_address.c_str());

	vrpnTracker->register_change_handler(0, handle_tracker);
	vrpnText->register_message_handler(0, handle_message);


	//Create VRPN Server Connection
	vrpn_Connection_IP* m_Connection = new vrpn_Connection_IP(port);
	//Create VRPN server Tracker. !!! Specify adrees of computer running the task controller and tracker name (can be freely choosen)
	vrpn_server_class* vrpn_server = new vrpn_server_class(server_address.c_str(), m_Connection);

	//initializize graphic window values 
	int window_length = 1200;
	int window_height = 1000;
	int random_x, random_y;
	int stage = 1; //starting task stage
	int target_radius = 30;
	int hand_radius = 5;

	double  targetx_dir = 0, targety_dir = 0,norm;  

	bool is_bci = false;

	int trial_counter = 0;
	

	//initialize objects 
	sf::RenderWindow window(sf::VideoMode(window_length, window_height), "Task Window");
	window.setVerticalSyncEnabled(true);
	sf::Vector2i windowposition(60, 300);
	window.setPosition(windowposition);
	sf::CircleShape fixPoint(target_radius), hand(hand_radius), target(target_radius), bci(hand_radius);
	fixPoint.setFillColor(sf::Color(150, 150, 150));
	fixPoint.setOrigin(target_radius, target_radius);
	fixPoint.setPosition(window_length / 2, window_height / 2);
	target.setFillColor(sf::Color(0, 150, 0));
	target.setOrigin(target_radius, target_radius);
	
	hand.setFillColor(sf::Color(150, 0, 0));
	hand.setOrigin(hand_radius, hand_radius);
	hand.setPosition(10.f, 50.f);
	bci.setFillColor(sf::Color(0, 150, 0));
	bci.setOrigin(hand_radius, hand_radius);
	bci.setPosition(10.f, 50.f);
   


	//initialize clock for timeout
	sf::Clock clock; // starts the clock
	sf::Time elapsed1; 
	//uinitialize vecotros representing positions
	sf::Vector2f targetPos, fixPos;


	while (window.isOpen())
	{
		sf::Event event;
		while (window.pollEvent(event))
		{
			if (event.type == sf::Event::Closed)
				window.close();
		}

		//start vrpn client
		vrpnTracker->mainloop();
		vrpnText->mainloop();

		
		if (stage == 1)
		{

			window.draw(fixPoint);
		}
		else
		{
			window.draw(target);
		}
		
		if (is_bci == true)
		{
			window.draw(bci);
		}
		else
		{

			window.draw(hand);
		}
		
		window.display();
		
		sf::Vector2i mousePosition = sf::Mouse::getPosition(window);
		sf::Vector2i bciPosition(dpi*temp[2] / 25.4, dpi*temp[3] / 25.4);
		target.setOrigin(target_radius, target_radius);
		
		//display task related variables
		
		//std::cout << "x: " << localPosition.x*25.4/dpi << " y: " << localPosition.y*25.4/dpi << std::endl;
		
		sf::sleep(sf::milliseconds(2));

		elapsed1 = clock.getElapsedTime();

			window.clear();
			
			hand.setPosition(mousePosition.x, mousePosition.y);
			bci.setPosition(bciPosition.x, bciPosition.y);
			
			vrpn_server->send_message("STAGE," + std::to_string(stage));
			
			
			//stage 1 (move to center)
			if ((abs(mousePosition.x - fixPos.x) < target_radius / 2) & (abs(mousePosition.y - fixPos.y) < target_radius / 2) & stage == 1)
			{
				
				random_x = (rand() % window_length-4*target_radius) + 4*target_radius;
				random_y = (rand() % window_height - 4*target_radius) + 4*target_radius;
				target.setPosition(random_x, random_y);
				targetx_dir = (random_x - fixPos.x);
				targety_dir = (random_y - fixPos.x);
				norm = sqrt(pow(targetx_dir, 2) + pow(targety_dir, 2));
				targetx_dir = targetx_dir / norm;
				targety_dir = targety_dir / norm;
			    
				
				
				vrpn_server->send_message("X_FIXATION," + std::to_string(fixPos.x*25.4 / dpi));
				vrpn_server->send_message("Y_FIXATION," + std::to_string(fixPos.y*25.4 / dpi));
				vrpn_server->send_message("REFERENCE_X_DIRECTION," + std::to_string(random_x*25.4 / dpi));
				vrpn_server->send_message("REFERENCE_Y_DIRECTION," + std::to_string(random_y*25.4 / dpi));
			
				stage = 2;
				clock.restart();
				
			}
			targetPos = target.getPosition();
			fixPos = fixPoint.getPosition();

		    
			//mouse control for acquire target Stage 2 (move to target) and Stage 3 (reward stage) and back to stage 1 (go to center)  
			if (!is_bci  & abs(mousePosition.x - targetPos.x) < target_radius & abs(mousePosition.y - targetPos.y) < target_radius & stage == 2)
			{

				stage = 3;
				vrpn_server->send_message("STAGE," + std::to_string(stage));
				sf::sleep(sf::milliseconds(300));;
				stage = 1;
				trial_counter += 1;
				vrpn_server->send_message("TRIAL," +std::to_string(trial_counter));
				clock.restart();

			}
			//bci control for acquire target
			if (is_bci  & abs(bciPosition.x - targetPos.x) < target_radius & abs(bciPosition.y  - targetPos.y) < target_radius & stage == 2)
			{

				stage = 3;
				vrpn_server->send_message("STAGE," + std::to_string(stage));
				sf::sleep(sf::milliseconds(300));
				stage = 1;
				trial_counter += 1;
				vrpn_server->send_message("TRIAL," + std::to_string(trial_counter));
				clock.restart();

			}

			//handle timeout in the first stage to avoid BCI buffer to be full
			if (stage == 1 & elapsed1.asSeconds() > 10)
			{
				//target.setFillColor(sf::Color(0, 0, 0));
				//fixPoint.setFillColor(sf::Color(150, 150, 150));
				stage = 1;
				trial_counter += 1;
				vrpn_server->send_message("TRIAL," + std::to_string(trial_counter));
				clock.restart();
			}


			//handle timeout during movement
			if (stage == 2 & elapsed1.asSeconds() > 3)
			{
				//target.setFillColor(sf::Color(0, 0, 0));
				//fixPoint.setFillColor(sf::Color(150, 150, 150));
				stage = 1;
				trial_counter += 1;
				vrpn_server->send_message("TRIAL," + std::to_string(trial_counter));
				clock.restart();
			}



			if (message.compare("BCION") == 0)
			{
				//Sleep(10);
				sf::sleep(sf::milliseconds(10));
				is_bci = true;
				std::cout << "BCI_stat: "<< is_bci << std::endl;
				message = "";//clear nessage once received
			
			
			}

			if (message.compare("BCIOFF") == 0)
			{
				//Sleep(10);
				sf::sleep(sf::milliseconds(10));
				is_bci = false;
				std::cout << "BCI_stat: " << is_bci << std::endl;
				message = "";//clear nessage once received


			}
			

            //send cursor position info to BCI 
			vrpn_server->set_position(mousePosition.x*25.4 / dpi, mousePosition.y*25.4 / dpi, 0);
			//vrpn_server->send_message("");	
	    
	}

	return 0;
}