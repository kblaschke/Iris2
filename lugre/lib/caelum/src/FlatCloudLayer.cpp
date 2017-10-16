/*
This file is part of Caelum.
See http://www.ogre3d.org/wiki/index.php/Caelum 

Copyright (c) 2008 Caelum team. See Contributors.txt for details.

Caelum is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Caelum is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Caelum. If not, see <http://www.gnu.org/licenses/>.
*/

#include "CaelumPrecompiled.h"
#include "FlatCloudLayer.h"
#include "CaelumExceptions.h"

namespace Caelum
{
	FlatCloudLayer::FlatCloudLayer(
            Ogre::SceneManager *sceneMgr,
			Ogre::SceneNode *cloudRoot)
	{
        Ogre::String uniqueId = Ogre::StringConverter::toString((size_t)this);
        Ogre::String materialName = "Caelum/FlatCloudLayer/Material/" + uniqueId;

		// Clone material
        Ogre::MaterialPtr originalMaterial = Ogre::MaterialManager::getSingleton ().getByName ("CaelumLayeredClouds");
		if (originalMaterial.isNull ()) {
			CAELUM_THROW_UNSUPPORTED_EXCEPTION (
                    "Can't find material resource \"CaelumLayeredClouds\"",
                    "FlatCloudLayer");
		}
		mMaterial.reset(originalMaterial->clone (materialName));
		mMaterial->load ();
		if (mMaterial->getBestTechnique () == 0) {
            CAELUM_THROW_UNSUPPORTED_EXCEPTION (
                    "Can't load flat cloud layer material: " + mMaterial->getUnsupportedTechniquesExplanation(),
                    "FlatCloudLayer");
		}

 		// Ignore missing shader parameters in clones material.
		getFpParams()->setIgnoreMissingParams(true);
		getVpParams()->setIgnoreMissingParams(true);

        // Create the scene node.
		mSceneMgr = sceneMgr;
		mNode.reset(cloudRoot->createChildSceneNode());
		mNode->setPosition(Ogre::Vector3(0, 0, 0));

        // Noise texture names are fixed.
        mNoiseTextureNames.clear();
        mNoiseTextureNames.push_back("noise1.dds");
        mNoiseTextureNames.push_back("noise2.dds");
        mNoiseTextureNames.push_back("noise3.dds");
        mNoiseTextureNames.push_back("noise4.dds");

        // Invalid; will reset on first opportunity.
        mCurrentTextureIndex = -1;

        // By default height is 0; the user is expected to change this.
		setHeight(0);		

        // Reset parameters. This is relied upon to initialize most fields.
        this->reset();

        // Ensure geometry; don't wait for first update.
        this->_ensureGeometry();
	}
	
	FlatCloudLayer::~FlatCloudLayer()
    {
		mSceneMgr = 0;

        // Rely on OwnedPtr for everything interesting.
	}	

    void FlatCloudLayer::_invalidateGeometry () {
        mMeshDirty = true;
    }

    void FlatCloudLayer::_ensureGeometry ()
    {
        if (!mMeshDirty) {
            return;
        }

        // Generate unique names based on pointer.
        Ogre::String uniqueId = Ogre::StringConverter::toString((size_t)this);
        Ogre::String planeMeshName = "Caelum/FlatCloudLayer/Plane/" + uniqueId;
        Ogre::String entityName = "Caelum/FlatCloudLayer/Entity/" + uniqueId;

        // Cleanup first. Entity references mesh so it must be destroyed first.
        mEntity.reset();
        mMesh.reset();

        /*
        Ogre::LogManager::getSingleton().logMessage(
                "Creating cloud layer mesh " +
                Ogre::StringConverter::toString(mMeshWidthSegments) + "x" +
                Ogre::StringConverter::toString(mMeshHeightSegments) + " segments");
         */

        // Recreate mesh.
        Ogre::Plane meshPlane(
                Ogre::Vector3(1, 1, 0),
                Ogre::Vector3(1, 1, 1),
                Ogre::Vector3(0, 1, 1));
		mMesh.reset(Ogre::MeshManager::getSingleton().createPlane(
                planeMeshName, Caelum::RESOURCE_GROUP_NAME, meshPlane,
                mMeshWidth, mMeshHeight,
			    mMeshWidthSegments, mMeshHeightSegments,
                false, 1,
                1.0f, 1.0f,
			    Ogre::Vector3::UNIT_X));

        // Recreate entity.
		mEntity.reset(mSceneMgr->createEntity(entityName, mMesh->getName()));
		mEntity->setMaterialName(mMaterial->getName());

        // Reattach entity.
		mNode->attachObject(mEntity.get());

        // Mark done.
        mMeshDirty = false;
    }

    void FlatCloudLayer::setMeshParameters (
            Real meshWidth, Real meshHeight,
            int meshWidthSegments, int meshHeightSegments)
    {
        bool invalidate =
                (mMeshWidthSegments != meshWidthSegments) ||
                (mMeshHeightSegments != meshHeightSegments) ||
                (abs(mMeshWidth - meshWidth) > 0.001) ||
                (abs(mMeshHeight - meshHeight) > 0.001);
        mMeshWidth = meshWidth;
        mMeshHeight = meshHeight;
        mMeshWidthSegments = meshWidthSegments;
        mMeshHeightSegments = meshHeightSegments;
        if (invalidate) {
            _invalidateGeometry();
        }
    }

	void FlatCloudLayer::reset()
    {
        _invalidateGeometry ();
        setMeshParameters(10000000, 10000000, 10, 10);

        assert (mCloudCoverLookup.get() == 0);
        setCloudCoverLookup ("CloudCoverLookup.png");
		setCloudCover (0.3);

		setCloudMassOffset (Ogre::Vector2(0, 0));
		setCloudDetailOffset (Ogre::Vector2(0, 0));
		setCloudBlendTime (3600 * 24);
		setCloudBlendPos (0.5);

		setCloudSpeed (Ogre::Vector2(0.000005, -0.000009));

		setCloudUVFactor (150);
		setHeightRedFactor (100000);

        setFadeDistances (10000, 140000);
    }

	void FlatCloudLayer::update (
            Ogre::Real timePassed,
			const Ogre::Vector3 &sunDirection,
			const Ogre::ColourValue &sunLightColour,
			const Ogre::ColourValue &fogColour,
			const Ogre::ColourValue &sunSphereColour)
	{
	    // Set sun parameters.
		setSunDirection(sunDirection);
		setSunLightColour(sunLightColour);
		setSunSphereColour(sunSphereColour);
		setFogColour(fogColour);

	    // Move clouds.
		setCloudMassOffset(mCloudMassOffset + timePassed * mCloudSpeed);
		setCloudDetailOffset(mCloudDetailOffset - timePassed * mCloudSpeed);

		// Animate cloud blending.
        setCloudBlendPos (getCloudBlendPos () + timePassed / mCloudBlendTime);

        this->_ensureGeometry();
	}	

	Ogre::GpuProgramParametersSharedPtr FlatCloudLayer::getVpParams() {
		return mMaterial->getBestTechnique()->getPass(0)->getVertexProgramParameters();
	}

	Ogre::GpuProgramParametersSharedPtr FlatCloudLayer::getFpParams() {
		return mMaterial->getBestTechnique()->getPass(0)->getFragmentProgramParameters();
	}

	void FlatCloudLayer::setCloudCoverLookup (const Ogre::String& fileName) {
        mCloudCoverLookup.reset(0);
        mCloudCoverLookup.reset(new Ogre::Image());
        mCloudCoverLookup->load(fileName, RESOURCE_GROUP_NAME);
    }

	void FlatCloudLayer::setCloudCover(const Ogre::Real cloudCover) {
        mCloudCover = cloudCover;
		float cloudCoverageThreshold = 0;
        if (mCloudCoverLookup.get() != 0) {
			cloudCoverageThreshold = getInterpolatedColour(cloudCover, 1, mCloudCoverLookup.get(), false).r;
        } else {
            cloudCoverageThreshold = 1 - cloudCover;   
        }
		getFpParams()->setNamedConstant("cloudCoverageThreshold", cloudCoverageThreshold);
	}

	void FlatCloudLayer::setCloudMassOffset(const Ogre::Vector2 &cloudMassOffset) {
		mCloudMassOffset = cloudMassOffset;		
		getFpParams()->setNamedConstant("cloudMassOffset", Ogre::Vector3(cloudMassOffset.x,cloudMassOffset.y,0));		
	}

	void FlatCloudLayer::setCloudDetailOffset(const Ogre::Vector2 &cloudDetailOffset) {
		mCloudDetailOffset = cloudDetailOffset;
		getFpParams()->setNamedConstant("cloudDetailOffset", Ogre::Vector3(cloudDetailOffset.x,cloudDetailOffset.y,0));		
	}

	void FlatCloudLayer::setCloudBlendTime(const Ogre::Real value) {
		mCloudBlendTime = value;
	}

    Ogre::Real FlatCloudLayer::getCloudBlendTime () const {
        return mCloudBlendTime;
    }

    void FlatCloudLayer::setCloudBlendPos (const Ogre::Real value)
    {
        mCloudBlendPos = value;
        int textureCount = static_cast<int>(mNoiseTextureNames.size());

        // Convert to int and bring to [0, textureCount)
        int currentTextureIndex = static_cast<int>(floor(mCloudBlendPos));
        currentTextureIndex = ((currentTextureIndex % textureCount) + textureCount) % textureCount;
        assert(0 <= currentTextureIndex);
        assert(currentTextureIndex < textureCount);

        // Check if we have to change textures.
        if (currentTextureIndex != mCurrentTextureIndex) {
            String texture1 = mNoiseTextureNames[currentTextureIndex];
            String texture2 = mNoiseTextureNames[(currentTextureIndex + 1) % textureCount];
            //Ogre::LogManager::getSingleton ().logMessage (
            //        "Caelum: Switching cloud layer textures to " + texture1 + " and " + texture2);
            Ogre::Pass* pass = mMaterial->getBestTechnique()->getPass(0);
            pass->getTextureUnitState(0)->setTextureName(texture1);
            pass->getTextureUnitState(1)->setTextureName(texture2);
            mCurrentTextureIndex = currentTextureIndex;
        }

        Ogre::Real cloudMassBlend = fmod(mCloudBlendPos, 1);
		getFpParams()->setNamedConstant("cloudMassBlend", cloudMassBlend);
    }

    Ogre::Real FlatCloudLayer::getCloudBlendPos () const {
        return mCloudBlendPos;
    }

	void FlatCloudLayer::setCloudSpeed(const Ogre::Vector2 &cloudSpeed) {
		mCloudSpeed = cloudSpeed;
	}

	void FlatCloudLayer::setSunDirection(const Ogre::Vector3 &sunDirection) {
		getVpParams()->setNamedConstant("sunDirection", sunDirection);
		getFpParams()->setNamedConstant("sunDirection", sunDirection);
	}

	void FlatCloudLayer::setSunLightColour(const Ogre::ColourValue &sunLightColour) {
		getFpParams()->setNamedConstant("sunLightColour", sunLightColour);
	}

	void FlatCloudLayer::setSunSphereColour(const Ogre::ColourValue &sunSphereColour) {
		getFpParams()->setNamedConstant("sunSphereColour", sunSphereColour);
	}

	void FlatCloudLayer::setFogColour(const Ogre::ColourValue &fogColour) {
		getFpParams()->setNamedConstant("fogColour", fogColour);
	}

	void FlatCloudLayer::setHeight(Ogre::Real height) {
		mNode->setPosition(Ogre::Vector3(0, height, 0));
		mHeight = height;
		getFpParams()->setNamedConstant("layerHeight", mHeight);
	}

    Ogre::Real FlatCloudLayer::getHeight() const {
		return mHeight;
	}

    void FlatCloudLayer::setCloudUVFactor (const Ogre::Real value) {
		getFpParams()->setNamedConstant("cloudUVFactor", mCloudUVFactor = value);
    }

    void FlatCloudLayer::setHeightRedFactor (const Ogre::Real value) {
		getFpParams()->setNamedConstant("heightRedFactor", mHeightRedFactor = value);
    }

    void FlatCloudLayer::setFadeDistances (const Ogre::Real nearValue, const Ogre::Real farValue) {
        setNearFadeDist (nearValue);
        setFarFadeDist (farValue);
    }

    void FlatCloudLayer::setNearFadeDist (const Ogre::Real value) {
		getFpParams()->setNamedConstant("nearFadeDist", mNearFadeDist = value);
    }

    void FlatCloudLayer::setFarFadeDist (const Ogre::Real value) {
		getFpParams()->setNamedConstant("farFadeDist", mFarFadeDist = value);
    }
}
