import { Link } from "react-router"

const Navbar = () => {
  return (
    <div className="navbar bg-base-300 shadow-md px-4">
          <div className="flex-1">
            <a className="btn btn-ghost text-xl">SubSync</a>

          </div>
          <div className="flex-none gap-2"><ul className="menu menu-horizontal px-1 hidden md:flex">
          <li><Link to="/">Home</Link></li>
          <li><Link to="/subscriptions">My Subscriptions</Link></li>
          <li><Link to="/dashboard">Company Dashboard</Link></li>
        </ul></div>


    </div>
  );
}

export default Navbar