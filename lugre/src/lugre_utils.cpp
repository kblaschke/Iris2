#include "lugre_prefix.h"
#include "lugre_utils.h"
#include "lugre_profile.h"

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <stdexcept>

using namespace Lugre;

namespace Lugre {

std::string GetFileContent(const std::string &filename){ PROFILE
	std::ifstream myfile(filename.c_str());
	
	if (myfile.is_open()){
		std::string line;
		std::stringstream out;
		
		while (! myfile.eof() ){
			getline (myfile,line);
			out << line;
		}
		
		myfile.close();
		
		return out.str();
	}
	
	throw std::runtime_error(std::string("could not read file: ") + filename);
}

}
