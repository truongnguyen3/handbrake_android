﻿// --------------------------------------------------------------------------------------------------------------------
// <copyright file="SubImport.cs" company="HandBrake Project (https://handbrake.fr)">
//   This file is part of the HandBrake source code - It may be used under the terms of the GNU General Public License.
// </copyright>
// <summary>
//   The srt.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace HandBrake.Interop.Interop.Json.Encode
{
    /// <summary>
    /// The srt.
    /// </summary>
    public class SubImport
    {
        /// <summary>
        /// Gets or sets the codeset.
        /// </summary>
        public string Codeset { get; set; }

        /// <summary>
        /// Gets or sets the filename.
        /// </summary>
        public string Filename { get; set; }

        /// <summary>
        /// Gets or sets the language.
        /// </summary>
        public string Language { get; set; }

        public string Format { get; set; }
    }
}