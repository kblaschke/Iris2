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

#ifndef CAELUM__FLAT_CLOUD_LAYER_H
#define CAELUM__FLAT_CLOUD_LAYER_H

#include "CaelumPrerequisites.h"
#include "ImageHelper.h"
#include "OwnedPtr.h"

namespace Caelum
{
    /** A flat cloud layer; drawn as a simple plane.
     *  Supports movement and variable cloud cover.
     *  @note This is tighly integrated with LayeredCloud.cg and LayeredClouds.material.
     */
	class CAELUM_EXPORT FlatCloudLayer : public Lugre::cSmartPointable
	{
	public:
		FlatCloudLayer(
				Ogre::SceneManager *sceneMgr,
                Ogre::SceneNode *cloudRoot);

		~FlatCloudLayer();

        /** Update function called each frame from above.
         */
	    void update (
                Ogre::Real timePassed,
		        const Ogre::Vector3 &sunDirection,
		        const Ogre::ColourValue &sunLightColour,
		        const Ogre::ColourValue &fogColour,
				const Ogre::ColourValue &sunSphereColour);

        /** Reset most tweak settings to their default values
         */
        void reset ();

	private:
        Ogre::Real mHeight;
	    Ogre::Real mCloudCover;

	    Ogre::Vector2 mCloudSpeed;
	    Ogre::Vector2 mCloudMassOffset;
	    Ogre::Vector2 mCloudDetailOffset;

		/// Current cloud blend position; from 0 to mNoiseTextureNames.size()
	    Ogre::Real mCloudBlendPos;
        /// Current index in the set of textures.
        /// Cached to avoid setting textures every frame.
        int mCurrentTextureIndex;

        /// Time required to blend two cloud shapes.
	    Ogre::Real mCloudBlendTime;

        std::vector<String> mNoiseTextureNames;

        /// Lookup used for cloud coverage, @see setCloudCoverLookup.
        std::auto_ptr<Ogre::Image> mCloudCoverLookup;

	    Ogre::GpuProgramParametersSharedPtr getVpParams();
	    Ogre::GpuProgramParametersSharedPtr getFpParams();

        // Set various internal parameters:
	    void setCloudMassOffset(const Ogre::Vector2 &cloudMassOffset);
	    void setCloudDetailOffset(const Ogre::Vector2 &cloudDetailOffset);
	    void setSunDirection(const Ogre::Vector3 &sunDirection);
	    void setSunLightColour(const Ogre::ColourValue &sunLightColour);
		void setSunSphereColour(const Ogre::ColourValue &sunSphereColour);
	    void setFogColour(const Ogre::ColourValue &fogColour);

    private:
	    Ogre::SceneManager *mSceneMgr;

        // Note: objects are destroyed in reverse order of declaration.
        // This means that objects must be ordered by dependency.
	    OwnedMaterialPtr mMaterial;		
        OwnedMeshPtr mMesh;
	    SceneNodePtr mNode;
	    EntityPtr mEntity;

        // Mesh parameters.
        bool mMeshDirty;
        Real mMeshWidth, mMeshHeight;
        int mMeshWidthSegments, mMeshHeightSegments;

    public:
        /** Regenerate the plane mesh and recreate entity.
         *  This automatically happens in update.
         */
        void _ensureGeometry();

        /** Regenerate the plane mesh and recreate entity.
         *  This automatically happens when mesh parameters are changed.
         */
        void _invalidateGeometry();

        /** Reset all mesh parameters.
         */
        void setMeshParameters (
                Real meshWidth, Real meshHeight,
                int meshWidthSegments, int meshHeightSegments);

        /// @see setMeshParameters
        inline void setMeshWidth (Real value) { mMeshWidth = value; _invalidateGeometry (); }
        inline void setMeshHeight (Real value) { mMeshHeight = value; _invalidateGeometry (); }
        inline void setMeshWidthSegments (int value) { mMeshWidthSegments = value; _invalidateGeometry (); }
        inline void setMeshHeightSegments (int value) { mMeshHeightSegments = value; _invalidateGeometry (); }
        inline Real getMeshWidth () const { return mMeshWidth; }
        inline Real getMeshHeight () const { return mMeshHeight; }
        inline int getMeshWidthSegments () const { return mMeshWidthSegments; }
        inline int getMeshHeightSegments () const { return mMeshHeightSegments; }

    public:
        /** Set the height of the cloud layer.
         *  @param height In world units above the cloud root node.
         */
        void setHeight(Ogre::Real height);

        /** Get the height of the cloud layer.
         *  @return height In world units above the cloud root node.
         */
        Ogre::Real getHeight() const;

        /** Sets cloud movement speed.
		 *  @param cloudSpeed Cloud movement speed.
		 */
		void setCloudSpeed (const Ogre::Vector2 &cloudSpeed);

		/** Gets cloud movement speed.
		 *  @param cloudSpeed Cloud movement speed.
		 */
        const Ogre::Vector2 getCloudSpeed () const { return mCloudSpeed; }

		/** Sets cloud cover, between 0 (completely clear) and 1 (completely covered)
		 *  @param cloudCover Cloud cover between 0 and 1
		 */
		void setCloudCover (const Ogre::Real cloudCover);

		/** Gets the current cloud cover.
		 *  @return Cloud cover, between 0 and 1
		 */
        inline Ogre::Real getCloudCover () const { return mCloudCover; }

        /** Set the image used to lookup the cloud coverage threshold.
         *  This image is used to calculate the cloud coverage threshold
         *  based on the desired cloud cover.
         *
         *  The cloud coverage threshold is substracted from cloud intensity
         *  at any point; to generate fewer or more clouds. That threshold is
         *  not linear, a lookup is required to ensure that setCloudCover(0.1)
         *  will actually have 10% the clouds at setCloudCover(1).
         *
         *  The lookup is the inverse of the sum on the histogram, and was
         *  calculated with a small hacky tool.
         */
	    void setCloudCoverLookup (const Ogre::String& fileName);

        /** Disable any cloud cover lookup.
         *  @see setCloudCoverLookup.
         */
        void disableCloudCoverLookup ();

	    /** Sets the time it takes to blend two cloud shaped together, in seconds.
         *  This will also reset the animation at the current time.
		 *  @param value Cloud shape blend time in seconds
		 */
		void setCloudBlendTime (const Ogre::Real value);

		/** Gets the time it takes to blend two cloud shaped together, in seconds.
		 *  @return Cloud shape blend time in seconds
		 */
		Ogre::Real getCloudBlendTime () const;

        /** Set the current blending position; between noise textures.
         *  Integer values are used for single textures. Float values blend between two textures.
         *  Values outside [0, textureCount) are wrapped around.
         *  @param value New cloud blending position
         */
	    void setCloudBlendPos (const Ogre::Real value);

        /// @see setCloudBlendPos
        Ogre::Real getCloudBlendPos () const;

    private:
        Ogre::Real mCloudUVFactor;
        Ogre::Real mHeightRedFactor;

    public:
        /** Cloud texture coordinates are multiplied with this.
         *  Higher values result in more spread-out clouds.
         *  Very low value result in ugly texture repeats.
         */
	    void setCloudUVFactor (const Ogre::Real value);
        /// @see setCloudUVFactor
        inline Ogre::Real getCloudUVFactor () const { return mCloudUVFactor; }

        /** High-altitude clouds are tinted red in the evening.
         *  Higher values attenuate the effect.
         */
	    void setHeightRedFactor (const Ogre::Real value);
        /// @see setCloudUVFactor
        Ogre::Real getHeightRedFactor () const { return mHeightRedFactor; }

    private:
        Ogre::Real mNearFadeDist;
        Ogre::Real mFarFadeDist;

    public:
        /** Cloud fade distances.
         *
         *  These are measured horizontally in meters (height is not used).
         *
         *  The effect is a fade based on alpha blending which occurs between
         *  nearValue and farValue. After farValue nothing is visibile from
         *  this layer.
         *
         *  Default values are 10000 and 140000
         */
        void setFadeDistances (Ogre::Real nearValue, Ogre::Real farValue);

	    void setNearFadeDist (const Ogre::Real value);
        Ogre::Real getNearFadeDist () const { return mNearFadeDist; }

	    void setFarFadeDist (const Ogre::Real value);
        Ogre::Real getFarFadeDist () const { return mFarFadeDist; }

    public:
        void setQueryFlags (uint flags) { mEntity->setQueryFlags (flags); }
        uint getQueryFlags () const { return mEntity->getQueryFlags (); }
        void setVisibilityFlags (uint flags) { mEntity->setVisibilityFlags (flags); }
        uint getVisibilityFlags () const { return mEntity->getVisibilityFlags (); }
	};
}

#endif // CAELUM__FLAT_CLOUD_LAYER_H
